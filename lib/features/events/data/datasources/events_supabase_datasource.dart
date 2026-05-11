import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/domain/normalized_location.dart';
import '../../../../core/supabase/location_write_helper.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/create_event_data.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/event_filters.dart';
import '../../domain/entities/order.dart' as events_domain;
import '../../domain/entities/selected_ticket.dart';
import '../../domain/entities/ticket_type.dart';
import '../models/event_detail_model.dart';
import '../models/event_list_item_model.dart';
import '../models/order_model.dart';
import '../models/ticket_model.dart';
import '../models/ticket_type_model.dart';
import 'events_remote_datasource.dart';

/// Supabase implementation of [EventsRemoteDataSource].
class EventsSupabaseDataSource implements EventsRemoteDataSource {
  EventsSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;
  static const double _serviceFeeRate = 0.05;
  static const Duration _paymentConfirmationMaxWait = Duration(seconds: 12);

  /// Adaptive poll cadence after Payment Sheet succeeds.
  /// Sync edge fn usually finalizes within ~200ms; webhook within 1-3s; cold
  /// starts within ~6s. We poll fast at the start, then back off.
  /// Each entry is (interval, attempts).
  static const List<(Duration, int)> _paymentStatusPollSchedule = [
    (Duration(milliseconds: 200), 5),
    (Duration(milliseconds: 500), 10),
    (Duration(milliseconds: 1000), 6),
  ];

  static EventCategory _categoryFromString(String? s) {
    if (s == null || s.isEmpty) return EventCategory.all;
    final lower = s.toLowerCase();
    final map = <String, EventCategory>{
      'concerts': EventCategory.concerts,
      'parties': EventCategory.parties,
      'cultural': EventCategory.cultural,
      'music': EventCategory.music,
      'nightlife': EventCategory.nightlife,
      'food': EventCategory.food,
      'networking': EventCategory.networking,
      'community': EventCategory.community,
    };
    return map[lower] ?? EventCategory.all;
  }

  static TicketStatus _ticketStatus(int available, int sold) {
    if (available <= 0) return TicketStatus.soldOut;
    if (available <= 5) return TicketStatus.lowStock;
    return TicketStatus.available;
  }

  /// Strips `%` and trims so PostgREST `ilike` patterns stay predictable.
  static String _sanitizeIlike(String? raw) {
    if (raw == null) return '';
    return raw.replaceAll('%', '').trim();
  }

  static bool _isMissingLocationsRelationship(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == 'PGRST200' ||
        (message.contains('locations') &&
            (message.contains('schema cache') ||
                message.contains('could not find') ||
                message.contains('relationship')));
  }

  @override
  Future<List<EventListItemModel>> getEvents({
    String? location,
    EventFilters? filters,
    String? searchQuery,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      Future<List<Map<String, dynamic>>> fetch(String select) async {
        var query = _client
            .from('events')
            .select(select)
            .eq('is_active', true)
            .gte('start_at', DateTime.now().toIso8601String());

        // TODO: Add location filter when ready: query.or('venue_name.ilike.%$location%,venue_address.ilike.%$location%')
        final q = _sanitizeIlike(searchQuery);
        if (q.isNotEmpty) {
          query = query.or(
            'title.ilike.%$q%,description.ilike.%$q%,venue_name.ilike.%$q%,venue_address.ilike.%$q%',
          );
        }
        final startDate = filters?.startDate;
        if (startDate != null) {
          query = query.gte('start_at', startDate.toIso8601String());
        }
        final endDate = filters?.endDate;
        if (endDate != null) {
          query = query.lte('end_at', endDate.toIso8601String());
        }
        if (filters?.eventTypes.isNotEmpty == true) {
          final types = filters!.eventTypes.map((e) => e.name).toList();
          query = query.inFilter('category', types);
        }

        final res = await query.order('start_at', ascending: true);
        return (res as List).cast<Map<String, dynamic>>();
      }

      // Embed ticket-type prices so list cards can show real $/range instead
      // of falling back to "Free". Try with locations + tickets first; degrade
      // gracefully if either embed isn't available.
      late final List<Map<String, dynamic>> list;
      try {
        list = await fetch(
          '*, ${SupabaseTables.locations}(*), '
          '${SupabaseTables.eventTickets}(price, quantity_available, quantity_sold)',
        );
      } on PostgrestException catch (e) {
        if (_isMissingLocationsRelationship(e)) {
          try {
            list = await fetch(
              '*, ${SupabaseTables.eventTickets}(price, quantity_available, quantity_sold)',
            );
          } on PostgrestException {
            list = await fetch('*');
          }
        } else if (_isMissingEventTicketsRelationship(e)) {
          list = await fetch('*, ${SupabaseTables.locations}(*)');
        } else {
          rethrow;
        }
      }
      return list.map(_rowToEventListItem).toList();
    });
  }

  @override
  Future<List<EventListItemModel>> getEventsByBusinessId(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      if (businessId.isEmpty) return <EventListItemModel>[];

      Future<List<Map<String, dynamic>>> fetch(String select) async {
        final res = await _client
            .from('events')
            .select(select)
            .eq('is_active', true)
            .eq('business_id', businessId)
            .gte('start_at', DateTime.now().toIso8601String())
            .order('start_at', ascending: true)
            .limit(50);
        return (res as List).cast<Map<String, dynamic>>();
      }

      late final List<Map<String, dynamic>> list;
      try {
        list = await fetch(
          '*, ${SupabaseTables.locations}(*), '
          '${SupabaseTables.eventTickets}(price, quantity_available, quantity_sold)',
        );
      } on PostgrestException catch (e) {
        if (_isMissingLocationsRelationship(e)) {
          try {
            list = await fetch(
              '*, ${SupabaseTables.eventTickets}(price, quantity_available, quantity_sold)',
            );
          } on PostgrestException {
            list = await fetch('*');
          }
        } else if (_isMissingEventTicketsRelationship(e)) {
          list = await fetch('*, ${SupabaseTables.locations}(*)');
        } else {
          rethrow;
        }
      }
      return list.map(_rowToEventListItem).toList();
    });
  }

  static bool _isMissingEventTicketsRelationship(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == 'PGRST200' &&
        (message.contains('event_tickets') ||
            message.contains('event tickets'));
  }

  EventListItemModel _rowToEventListItem(Map<String, dynamic> row) {
    final normalizedLocation =
        NormalizedLocation.maybeFromEmbedded(row[SupabaseTables.locations]);
    final isOnline = parseBool(row['is_online']);
    final id = parseStringRequired(row['id']);
    final title = parseStringRequired(row['title']);
    final imageUrl = parseString(row['image_url']) ?? 'https://placehold.co/400x300?text=Event';
    final category = parseString(row['category']);
    final categories = [ _categoryFromString(category) ];
    final startAt = parseTimestampRequired(row['start_at']);
    final venue = isOnline
        ? 'Online'
        : (normalizedLocation?.name ??
            parseStringRequired(row['venue_name'], 'Venue'));
    final venueAddress = isOnline
        ? parseString(row['online_url'])
        : (normalizedLocation?.displayAddress.isNotEmpty == true
            ? normalizedLocation!.displayAddress
            : parseString(row['venue_address']));
    final locationLabel = venueAddress ?? venue;

    final pricing = _pricingFromEmbeddedTickets(row[SupabaseTables.eventTickets]);

    return EventListItemModel(
      id: id,
      title: title,
      imageUrl: imageUrl,
      categories: categories,
      dateTime: startAt,
      venue: venue,
      location: locationLabel,
      price: pricing.price,
      priceRange: pricing.priceRange,
      isBookmarked: false,
    );
  }

  /// Computes `(price, priceRange)` from the embedded `event_tickets` rows.
  /// - No tickets or all $0          → both null (UI shows "Free")
  /// - Single non-zero price         → `price` set, `priceRange` null
  /// - Multiple distinct prices > 0  → `priceRange` like "$25 – $100"
  static ({double? price, String? priceRange}) _pricingFromEmbeddedTickets(
    dynamic embedded,
  ) {
    if (embedded is! List || embedded.isEmpty) {
      return (price: null, priceRange: null);
    }
    final priced = <double>[];
    for (final e in embedded) {
      if (e is! Map) continue;
      final p = parseDouble(e['price']);
      if (p == null) continue;
      // Skip ticket types that have nothing left to sell — pricing the card off
      // a sold-out tier is misleading.
      final qa = parseInt(e['quantity_available']);
      final qs = parseInt(e['quantity_sold']);
      if (qa != null && qs != null && qa - qs <= 0) continue;
      priced.add(p);
    }
    if (priced.isEmpty) return (price: null, priceRange: null);
    final positive = priced.where((p) => p > 0).toList();
    if (positive.isEmpty) return (price: null, priceRange: null);

    positive.sort();
    final lo = positive.first;
    final hi = positive.last;
    if (lo == hi) {
      return (price: lo, priceRange: null);
    }
    return (
      price: lo,
      priceRange: '\$${lo.toStringAsFixed(0)} – \$${hi.toStringAsFixed(0)}',
    );
  }

  @override
  Future<EventDetailModel> getEventDetail(String eventId) async {
    return SupabaseFailureMapper.guard(() async {
      dynamic eventRes;
      try {
        eventRes = await _client
            .from('events')
            .select('*, ${SupabaseTables.locations}(*)')
            .eq('id', eventId)
            .maybeSingle();
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST200' ||
            e.message.contains('could not find') ||
            e.message.contains('relationship') ||
            e.message.contains('locations')) {
          eventRes = await _client.from('events').select('*').eq('id', eventId).maybeSingle();
        } else {
          rethrow;
        }
      }
      if (eventRes == null) throw Exception('Event not found');
      final row = Map<String, dynamic>.from(eventRes as Map);

      final ticketsRes = await _client.from('event_tickets').select('*').eq('event_id', eventId);
      final ticketRows = (ticketsRes as List).cast<Map<String, dynamic>>();
      final ticketTypes = ticketRows.map((t) {
        final avail = parseInt(t['quantity_available']) ?? 0;
        final sold = parseInt(t['quantity_sold']) ?? 0;
        return TicketTypeModel(
          id: parseStringRequired(t['id']),
          name: parseStringRequired(t['name']),
          description: '',
          price: parseDouble(t['price']) ?? 0,
          status: _ticketStatus(avail, sold),
          availableQuantity: avail,
          icon: null,
        );
      }).toList();

      final category = parseString(row['category']);
      final location = NormalizedLocation.maybeFromEmbedded(row[SupabaseTables.locations]);
      final isOnline = parseBool(row['is_online']);
      final minPrice = ticketTypes.isEmpty ? null : ticketTypes.map((e) => e.price).reduce((a, b) => a < b ? a : b);
      final maxPrice = ticketTypes.isEmpty ? null : ticketTypes.map((e) => e.price).reduce((a, b) => a > b ? a : b);

      return EventDetailModel(
        id: parseStringRequired(row['id']),
        title: parseStringRequired(row['title']),
        description: parseStringRequired(row['description']),
        imageUrl: parseString(row['image_url']) ?? 'https://placehold.co/400x300?text=Event',
        categories: [ _categoryFromString(category) ],
        startDate: parseTimestampRequired(row['start_at']),
        endDate: parseTimestampRequired(row['end_at']),
        venue: isOnline
            ? 'Online'
            : (location?.name ?? parseStringRequired(row['venue_name'], 'Venue')),
        address: isOnline
            ? parseStringRequired(row['online_url'])
            : (location?.addressLine1 ?? parseStringRequired(row['venue_address'])),
        city: isOnline ? '' : (location?.city ?? ''),
        state: isOnline ? '' : (location?.state ?? ''),
        zipCode: isOnline ? null : location?.postalCode,
        latitude: isOnline ? null : (location?.latitude ?? parseDouble(row['venue_lat'])),
        longitude: isOnline ? null : (location?.longitude ?? parseDouble(row['venue_lng'])),
        minPrice: minPrice,
        maxPrice: maxPrice,
        organizer: null,
        isOnline: isOnline,
        onlineUrl: parseString(row['online_url']),
        ticketTypes: ticketTypes,
        isBookmarked: false,
        policies: _eventPoliciesFromRow(row),
      );
    });
  }

  String? _trimmedOrNull(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  List<String>? _eventPoliciesFromRow(Map<String, dynamic> row) {
    final raw = parseString(row['event_policy']);
    if (raw == null || raw.trim().isEmpty) return null;
    return raw
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  @override
  Future<List<EventListItemModel>> getSimilarEvents(String eventId) async {
    return SupabaseFailureMapper.guard(() async {
      final event = await _client.from('events').select('category').eq('id', eventId).maybeSingle();
      final category = event is Map ? parseString((event as Map<String, dynamic>)['category']) : null;
      var query = _client
          .from('events')
          .select(
            '*, ${SupabaseTables.eventTickets}(price, quantity_available, quantity_sold)',
          )
          .eq('is_active', true)
          .gte('start_at', DateTime.now().toIso8601String())
          .neq('id', eventId);
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      late final List<Map<String, dynamic>> list;
      try {
        final res = await query.limit(5);
        list = (res as List).cast<Map<String, dynamic>>();
      } on PostgrestException catch (e) {
        if (!_isMissingEventTicketsRelationship(e)) rethrow;
        // Fallback when event_tickets relation can't be embedded (e.g. legacy
        // env). Prices won't show on similar-event cards in that case.
        final fallback = await _client
            .from('events')
            .select('*')
            .eq('is_active', true)
            .gte('start_at', DateTime.now().toIso8601String())
            .neq('id', eventId)
            .limit(5);
        list = (fallback as List).cast<Map<String, dynamic>>();
      }
      return list.map(_rowToEventListItem).toList();
    });
  }

  @override
  Future<List<TicketModel>> getUserTickets({bool upcomingOnly = true}) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return <TicketModel>[];

      // 'cancelled' is excluded so user-removed orders disappear from the list.
      // 'refunded' is excluded because a refund is the post-completion terminal
      // state — the ticket already moved out of the "My Tickets" experience.
      final ordersRes = await _client
          .from('orders')
          .select('*')
          .eq('user_id', userId)
          .eq('type', 'event')
          .inFilter('status', [
            'pending',
            'processing',
            'completed',
            'failed',
          ])
          .order('created_at', ascending: false);

      final ordersList = (ordersRes as List).cast<Map<String, dynamic>>();
      if (ordersList.isEmpty) return <TicketModel>[];

      // Batch-fetch every ticket row for these orders in one round-trip
      // instead of one query per order.
      final orderIds = ordersList
          .map((m) => parseString(m['id']))
          .whereType<String>()
          .toList(growable: false);
      final ticketsRes = orderIds.isEmpty
          ? const <dynamic>[]
          : await _client.from('tickets').select('*').inFilter('order_id', orderIds);
      final ticketRowsByOrderId = <String, List<Map<String, dynamic>>>{};
      for (final t in ticketsRes) {
        final tm = Map<String, dynamic>.from(t as Map);
        final orderId = parseString(tm['order_id']);
        if (orderId == null) continue;
        ticketRowsByOrderId.putIfAbsent(orderId, () => []).add(tm);
      }

      // Pre-fetch each unique event_ticket once.
      final eventTicketIds = <String>{};
      for (final rows in ticketRowsByOrderId.values) {
        for (final tm in rows) {
          final etId = parseString(tm['event_ticket_id']);
          if (etId != null) eventTicketIds.add(etId);
        }
      }
      final eventTicketById = <String, Map<String, dynamic>>{};
      if (eventTicketIds.isNotEmpty) {
        final etRes = await _client
            .from('event_tickets')
            .select('*')
            .inFilter('id', eventTicketIds.toList(growable: false));
        for (final row in etRes as List) {
          final m = Map<String, dynamic>.from(row as Map);
          final id = parseString(m['id']);
          if (id != null) eventTicketById[id] = m;
        }
      }

      // Cache event detail per event id — orders to the same event reuse it.
      final eventDetailCache = <String, EventDetailModel>{};
      Future<EventDetailModel?> resolveEvent(String id) async {
        if (eventDetailCache.containsKey(id)) return eventDetailCache[id];
        try {
          final detail = await getEventDetail(id);
          eventDetailCache[id] = detail;
          return detail;
        } catch (_) {
          return null;
        }
      }

      final tickets = <TicketModel>[];
      final now = DateTime.now();
      for (final orderRow in ordersList) {
        final orderMap = Map<String, dynamic>.from(orderRow);
        final orderPaymentStatus = _parseOrderStatus(parseString(orderMap['status']));
        final eventId = parseString(orderMap['event_id']);
        if (eventId == null) continue;

        final eventDetail = await resolveEvent(eventId);
        if (eventDetail == null) continue;
        final isUpcoming = !eventDetail.startDate.isBefore(now);
        if (upcomingOnly != isUpcoming) continue;

        final orderId = parseString(orderMap['id']);
        if (orderId == null) continue;

        final paid = orderPaymentStatus == events_domain.OrderStatus.completed;
        final rows = ticketRowsByOrderId[orderId] ?? const <Map<String, dynamic>>[];

        if (rows.isEmpty) {
          tickets.add(_syntheticTicketForOrder(
            orderId: orderId,
            orderMap: orderMap,
            eventDetail: eventDetail,
            orderPaymentStatus: orderPaymentStatus,
          ));
          continue;
        }

        for (final tm in rows) {
          final etId = parseString(tm['event_ticket_id']);
          if (etId == null) continue;

          final etRow = eventTicketById[etId];
          final price = etRow != null ? parseDouble(etRow['price']) ?? 0.0 : 0.0;
          final name = etRow != null ? parseStringRequired(etRow['name']) : 'Ticket';

          tickets.add(TicketModel(
            id: parseStringRequired(tm['id']),
            ticketId: parseStringRequired(tm['id']),
            event: eventDetail,
            ticketTypeName: name,
            price: price,
            purchaseDate: parseTimestampRequired(orderMap['created_at']),
            orderId: orderId,
            isVerified: paid,
            qrCode: null,
            orderPaymentStatus: orderPaymentStatus,
          ));
        }
      }
      return tickets;
    });
  }

  @override
  Future<TicketModel> getTicketDetail(String ticketId) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final res = await _client
          .from('tickets')
          .select('*, orders!inner(*), event_tickets(*)')
          .eq('id', ticketId)
          .maybeSingle();
      if (res == null) throw Exception('Ticket not found');

      final row = Map<String, dynamic>.from(res as Map);
      final order = row['orders'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(row['orders'] as Map)
          : null;
      if (order == null) throw Exception('Ticket order not found');
      if (parseString(order['user_id']) != userId) throw Exception('Ticket not found');

      final orderPaymentStatus = _parseOrderStatus(parseString(order['status']));
      if (orderPaymentStatus == events_domain.OrderStatus.failed ||
          orderPaymentStatus == events_domain.OrderStatus.cancelled) {
        throw Exception('This order is no longer valid.');
      }

      final eventId = parseString(order['event_id']);
      if (eventId == null) throw Exception('Event not found');
      final eventDetail = await getEventDetail(eventId);
      final et = row['event_tickets'];
      final price = et is Map<String, dynamic> ? parseDouble(et['price']) ?? 0.0 : 0.0;
      final name = et is Map<String, dynamic> ? parseStringRequired(et['name']) : 'Ticket';
      final paid = orderPaymentStatus == events_domain.OrderStatus.completed;
      final ordId = parseString(order['id']);
      return TicketModel(
        id: parseStringRequired(row['id']),
        ticketId: parseStringRequired(row['id']),
        event: eventDetail,
        ticketTypeName: name,
        price: price,
        purchaseDate: parseTimestampRequired(row['created_at']),
        orderId: ordId ?? '',
        isVerified: paid,
        qrCode: null,
        orderPaymentStatus: orderPaymentStatus,
      );
    });
  }

  @override
  Future<OrderModel> createOrder({
    required String eventId,
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic> contactInfo,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final eventDetail = await getEventDetail(eventId);
      num subtotalAmount = 0;
      final selectedTickets = <SelectedTicket>[];
      for (final t in tickets) {
        final ticketTypeId = (t['ticket_type_id'] ?? t['event_ticket_id'] ?? t['ticketTypeId']) as String?;
        if (ticketTypeId == null) continue;
        final qty = (t['quantity'] as num?)?.toInt() ?? 1;
        final etRes = await _client.from('event_tickets').select('*').eq('id', ticketTypeId).maybeSingle();
        if (etRes is Map<String, dynamic>) {
          final price = parseDouble(etRes['price']) ?? 0;
          final name = parseStringRequired(etRes['name']);
          subtotalAmount += price * qty;
          final tt = TicketTypeModel(
            id: parseStringRequired(etRes['id']),
            name: name,
            description: '',
            price: price,
            status: TicketStatus.available,
            availableQuantity: null,
            icon: null,
          );
          selectedTickets.add(SelectedTicket(ticketType: tt, quantity: qty));
        }
      }

      final serviceFeeAmount = subtotalAmount * _serviceFeeRate;
      final totalAmount = subtotalAmount + serviceFeeAmount;
      final orderRes = await _client.from('orders').insert({
        'user_id': userId,
        'type': 'event',
        'event_id': eventId,
        'status': 'pending',
        'subtotal_amount': subtotalAmount,
        'service_fee_amount': serviceFeeAmount,
        'total_amount': totalAmount,
        'contact_email': contactInfo['email'] ?? '',
        'contact_phone': contactInfo['phone'] ?? '',
      }).select('id, created_at').single();

      final orderId = (orderRes as Map)['id'] as String;
      for (final st in selectedTickets) {
        for (var i = 0; i < st.quantity; i++) {
          await _client.from('tickets').insert({
            'order_id': orderId,
            'event_ticket_id': st.ticketType.id,
            'quantity': 1,
            'status': 'valid',
          });
        }
      }

      return OrderModel(
        id: orderId,
        event: eventDetail,
        tickets: selectedTickets,
        subtotal: subtotalAmount.toDouble(),
        serviceFee: serviceFeeAmount.toDouble(),
        total: totalAmount.toDouble(),
        createdAt: parseTimestampRequired((orderRes as Map)['created_at']),
        status: events_domain.OrderStatus.pending,
      );
    });
  }

  @override
  Future<OrderModel> processPayment({
    required String orderId,
    required Map<String, dynamic> paymentMethod,
    String? promoCode,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      final stripePaymentIntentId = parseString(
        paymentMethod['payment_intent_id'] ?? paymentMethod['paymentIntentId'],
      );
      final stripeCustomerId = parseString(
        paymentMethod['customer_id'] ?? paymentMethod['customerId'],
      );
      final paymentType = parseString(paymentMethod['type']) ?? 'stripe';
      final paymentId = parseString(paymentMethod['id']) ?? '';

      try {
        await _client.rpc('mark_event_order_processing', params: {
          'p_order_id': orderId,
          'p_payment_provider': 'stripe',
          'p_stripe_payment_intent_id': stripePaymentIntentId,
          'p_payment_method': paymentType,
          'p_payment_id': paymentId,
          'p_stripe_customer_id': stripeCustomerId,
        });
      } catch (_) {
        await _client.from('orders').update({
          'status': 'processing',
          'payment_provider': 'stripe',
          'stripe_payment_intent_id': stripePaymentIntentId,
          'stripe_customer_id': stripeCustomerId,
          'payment_method': paymentType,
          'payment_id': paymentId,
          'payment_started_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);
      }

      // Fast path: finalize from Stripe in Edge Function (same as webhook) without
      // waiting for Stripe→Supabase webhook delivery. When the function returns a
      // definitive status, skip polling entirely — saves up to 12s on the happy path.
      try {
        final syncRes = await _client.functions.invoke(
          AppConfig.stripeSyncOrderPaymentFunction,
          body: {'order_id': orderId},
        );
        final data = syncRes.data;
        if (data is Map) {
          final reportedStatus = parseString(data['orderStatus']);
          if (reportedStatus == 'completed' ||
              reportedStatus == 'failed' ||
              reportedStatus == 'cancelled' ||
              reportedStatus == 'refunded') {
            return await _fetchOrderModel(orderId);
          }
        }
      } catch (_) {
        // Webhook `stripe-event-webhook` can still complete the order.
      }

      final completion = await _pollOrderUntilTerminal(orderId);
      return completion ?? await _fetchOrderModel(orderId);
    });
  }

  /// Polls the order row using an adaptive backoff schedule.
  /// Returns the [OrderModel] once the order is in a terminal state (completed
  /// / failed / cancelled / refunded), or null if the overall deadline passed.
  Future<OrderModel?> _pollOrderUntilTerminal(String orderId) async {
    final deadline = DateTime.now().add(_paymentConfirmationMaxWait);
    for (final (interval, attempts) in _paymentStatusPollSchedule) {
      for (var i = 0; i < attempts; i++) {
        if (DateTime.now().isAfter(deadline)) return null;
        final status = await _fetchOrderStatus(orderId);
        if (status == events_domain.OrderStatus.completed ||
            status == events_domain.OrderStatus.failed ||
            status == events_domain.OrderStatus.cancelled ||
            status == events_domain.OrderStatus.refunded) {
          return await _fetchOrderModel(orderId);
        }
        await Future<void>.delayed(interval);
      }
    }
    return null;
  }

  @override
  Future<EventDetailModel> createEvent(CreateEventData data) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      if (data.ticketTypes.isEmpty) {
        throw Exception('Add at least one ticket type');
      }

      final payload = <String, dynamic>{
        'organizer_id': userId,
        'business_id': data.businessId,
        'title': data.title,
        'description': data.description,
        'venue_name': data.venueName,
        'venue_address': data.venueAddress,
        'venue_lat': data.venueLat,
        'venue_lng': data.venueLng,
        'location_name': data.locationName,
        'location_city': data.locationCity,
        'location_state': data.locationState,
        'location_country': data.locationCountry,
        'location_postal_code': data.locationPostalCode,
        'place_id': data.placeId,
        'google_maps_url': data.googleMapsUrl,
        'is_online': data.isOnline,
        'online_url': data.onlineUrl,
        'start_at': data.startAt.toIso8601String(),
        'end_at': data.endAt.toIso8601String(),
        'image_url': data.imageUrl,
        'category': data.category.name.toLowerCase(),
        'is_active': true,
        'event_policy': _trimmedOrNull(data.eventPolicy),
      };
      await LocationWriteHelper(_client).attachEventLocation(payload);

      final eventRes = await _client.from(SupabaseTables.events).insert(payload).select('id').single();

      final eventId = (eventRes as Map)['id'] as String;

      for (final tt in data.ticketTypes) {
        await _client.from(SupabaseTables.eventTickets).insert({
          'event_id': eventId,
          'name': tt.name,
          'price': tt.price,
          'quantity_available': tt.quantityAvailable,
          'quantity_sold': 0,
        });
      }

      return getEventDetail(eventId);
    });
  }

  @override
  Future<EventDetailModel> updateEvent(String eventId, CreateEventData data) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final existing = await _client
          .from(SupabaseTables.events)
          .select('organizer_id')
          .eq('id', eventId)
          .maybeSingle();
      if (existing == null) throw Exception('Event not found');
      final org = parseString(existing['organizer_id']);
      if (org != userId) {
        throw Exception('You can only edit events you organize');
      }

      final payload = <String, dynamic>{
        'business_id': data.businessId,
        'title': data.title,
        'description': data.description,
        'venue_name': data.venueName,
        'venue_address': data.venueAddress,
        'venue_lat': data.venueLat,
        'venue_lng': data.venueLng,
        'location_name': data.locationName,
        'location_city': data.locationCity,
        'location_state': data.locationState,
        'location_country': data.locationCountry,
        'location_postal_code': data.locationPostalCode,
        'place_id': data.placeId,
        'google_maps_url': data.googleMapsUrl,
        'is_online': data.isOnline,
        'online_url': data.onlineUrl,
        'start_at': data.startAt.toIso8601String(),
        'end_at': data.endAt.toIso8601String(),
        'image_url': data.imageUrl,
        'category': data.category.name.toLowerCase(),
        'event_policy': _trimmedOrNull(data.eventPolicy),
      };
      await LocationWriteHelper(_client).attachEventLocation(payload);

      await _client.from(SupabaseTables.events).update(payload).eq('id', eventId);

      return getEventDetail(eventId);
    });
  }

  Future<OrderModel> _fetchOrderModel(String orderId) async {
    final res = await _client.from('orders').select('*').eq('id', orderId).single();
    final row = Map<String, dynamic>.from(res as Map);
    final eventId = parseString(row['event_id']);
    if (eventId == null) throw Exception('Order event not found');

    final eventDetail = await getEventDetail(eventId);
    final ticketRows = await _client
        .from(SupabaseTables.tickets)
        .select('id')
        .eq('order_id', orderId);

    final issuedIds = <String>[];
    for (final r in ticketRows as List<dynamic>) {
      final ticketRow = Map<String, dynamic>.from(r as Map);
      final ticketId = parseString(ticketRow['id']);
      if (ticketId != null) issuedIds.add(ticketId);
    }

    final subtotal = parseDouble(row['subtotal_amount']) ??
        parseDouble(row['total_amount']) ??
        0;
    final serviceFee = parseDouble(row['service_fee_amount']) ?? 0;
    final total = parseDouble(row['total_amount']) ?? subtotal + serviceFee;

    return OrderModel(
      id: orderId,
      event: eventDetail,
      tickets: const [],
      subtotal: subtotal,
      serviceFee: serviceFee,
      total: total,
      createdAt: parseTimestampRequired(row['created_at']),
      status: _parseOrderStatus(parseString(row['status'])),
      issuedTicketIds: issuedIds,
    );
  }

  Future<events_domain.OrderStatus> _fetchOrderStatus(String orderId) async {
    final res = await _client.from('orders').select('status').eq('id', orderId).single();
    final row = Map<String, dynamic>.from(res as Map);
    return _parseOrderStatus(parseString(row['status']));
  }

  events_domain.OrderStatus _parseOrderStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'processing':
        return events_domain.OrderStatus.processing;
      case 'completed':
        return events_domain.OrderStatus.completed;
      case 'failed':
        return events_domain.OrderStatus.failed;
      case 'cancelled':
        return events_domain.OrderStatus.cancelled;
      case 'refunded':
        return events_domain.OrderStatus.refunded;
      default:
        return events_domain.OrderStatus.pending;
    }
  }

  /// One list row when `tickets` rows are missing (e.g. lag before inserts or RLS),
  /// so pending/processing orders still show on My Tickets.
  TicketModel _syntheticTicketForOrder({
    required String orderId,
    required Map<String, dynamic> orderMap,
    required EventDetailModel eventDetail,
    required events_domain.OrderStatus orderPaymentStatus,
  }) {
    final total = parseDouble(orderMap['total_amount']) ?? 0.0;
    final syntheticId = 'order-summary-$orderId';
    final paid = orderPaymentStatus == events_domain.OrderStatus.completed;
    return TicketModel(
      id: syntheticId,
      ticketId: syntheticId,
      event: eventDetail,
      ticketTypeName: 'Ticket order',
      price: total,
      purchaseDate: parseTimestampRequired(orderMap['created_at']),
      orderId: orderId,
      isVerified: paid,
      qrCode: null,
      orderPaymentStatus: orderPaymentStatus,
      isSyntheticOrderRow: true,
    );
  }

  /// Cancels an event order that was never completed (safe release for user abandon flow).
  ///
  /// Prefers the `cancel_unpaid_event_order(uuid)` RPC because it runs with
  /// SECURITY DEFINER server-side — that sidesteps RLS pitfalls on the orders
  /// table. Falls back to a direct UPDATE if the function isn\'t deployed yet
  /// (older environments) so the feature degrades instead of breaking.
  @override
  Future<void> cancelUnpaidEventOrder(String orderId) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      try {
        final res = await _client.rpc(
          'cancel_unpaid_event_order',
          params: {'p_order_id': orderId},
        );
        // The RPC returns the number of rows updated. 0 means the row slipped
        // out from under us (e.g. webhook completed it between the guard and
        // the UPDATE) — surface a refresh hint to the user.
        final rowCount = res is int
            ? res
            : (res is num ? res.toInt() : int.tryParse('$res'));
        if (rowCount != null && rowCount > 0) return;
        if (rowCount == 0) {
          throw Exception(
            'This ticket couldn\'t be removed. Please refresh and try again.',
          );
        }
        // Unexpected return shape — treat as success rather than blocking the
        // user, then let the background refresh reconcile.
        return;
      } on PostgrestException catch (e) {
        // RPC missing in this Supabase project — fall through to direct UPDATE
        // so older environments keep working until the migration is applied.
        final missing = e.code == 'PGRST202' ||
            e.code == '42883' ||
            e.message.toLowerCase().contains('could not find the function') ||
            e.message.toLowerCase().contains('does not exist');
        if (!missing) {
          // Surface the precise reason from our raise exception messages.
          final raw = (e.message).trim();
          throw Exception(_friendlyCancelError(raw));
        }
      }

      final updated = await _client
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('id', orderId)
          .eq('user_id', userId)
          .inFilter('status', ['pending', 'processing', 'failed'])
          .select('id');
      if (updated is List && updated.isEmpty) {
        throw Exception(
          'This ticket couldn\'t be removed. Run the latest Supabase migration '
          '(orders_user_can_cancel) so the cancel_unpaid_event_order RPC '
          'exists, or add an UPDATE policy on orders that lets a user cancel '
          'their own pending/processing/failed rows.',
        );
      }
    });
  }

  static String _friendlyCancelError(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('not_authenticated')) {
      return 'Sign in to remove this ticket.';
    }
    if (r.contains('order_not_found_or_not_yours')) {
      return 'This ticket is no longer on your account. Pull to refresh.';
    }
    if (r.contains('order_not_removable')) {
      return 'This ticket is already in a final state (likely paid, refunded, '
          'or cancelled). Pull to refresh.';
    }
    return raw;
  }
}
