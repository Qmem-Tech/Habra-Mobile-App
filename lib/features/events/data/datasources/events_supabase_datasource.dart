import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
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

  @override
  Future<List<EventListItemModel>> getEvents({
    String? location,
    EventFilters? filters,
    String? searchQuery,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      var query = _client
          .from('events')
          .select('*')
          .eq('is_active', true)
          .gte('start_at', DateTime.now().toIso8601String());

      // TODO: Add location filter when ready: query.or('venue_name.ilike.%$location%,venue_address.ilike.%$location%')
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
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
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(_rowToEventListItem).toList();
    });
  }

  EventListItemModel _rowToEventListItem(Map<String, dynamic> row) {
    final id = parseStringRequired(row['id']);
    final title = parseStringRequired(row['title']);
    final imageUrl = parseString(row['image_url']) ?? 'https://placehold.co/400x300?text=Event';
    final category = parseString(row['category']);
    final categories = [ _categoryFromString(category) ];
    final startAt = parseTimestampRequired(row['start_at']);
    final venue = parseStringRequired(row['venue_name'], 'Venue');
    final venueAddress = parseString(row['venue_address']);
    final location = venueAddress ?? venue;
    return EventListItemModel(
      id: id,
      title: title,
      imageUrl: imageUrl,
      categories: categories,
      dateTime: startAt,
      venue: venue,
      location: location,
      price: null,
      priceRange: null,
      isBookmarked: false,
    );
  }

  @override
  Future<EventDetailModel> getEventDetail(String eventId) async {
    return SupabaseFailureMapper.guard(() async {
      final eventRes = await _client.from('events').select('*').eq('id', eventId).maybeSingle();
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
        venue: parseStringRequired(row['venue_name'], 'Venue'),
        address: parseStringRequired(row['venue_address']),
        city: '',
        state: '',
        zipCode: null,
        latitude: parseDouble(row['venue_lat']),
        longitude: parseDouble(row['venue_lng']),
        minPrice: minPrice,
        maxPrice: maxPrice,
        organizer: null,
        ticketTypes: ticketTypes,
        isBookmarked: false,
        policies: null,
      );
    });
  }

  @override
  Future<List<EventListItemModel>> getSimilarEvents(String eventId) async {
    return SupabaseFailureMapper.guard(() async {
      final event = await _client.from('events').select('category').eq('id', eventId).maybeSingle();
      final category = event is Map ? parseString((event as Map<String, dynamic>)['category']) : null;
      var query = _client
          .from('events')
          .select('*')
          .eq('is_active', true)
          .gte('start_at', DateTime.now().toIso8601String())
          .neq('id', eventId);
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      final res = await query.limit(5);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(_rowToEventListItem).toList();
    });
  }

  @override
  Future<List<TicketModel>> getUserTickets({bool upcomingOnly = true}) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return <TicketModel>[];

      var query = _client
          .from('orders')
          .select('*, tickets(*, event_tickets(*), events(*))')
          .eq('user_id', userId)
          .eq('type', 'event');
      if (upcomingOnly) {
        query = query.gte('created_at', DateTime.now().subtract(const Duration(days: 365)).toIso8601String());
      }
      final ordersRes = await query;
      final ordersList = ordersRes as List;
      if (ordersList.isEmpty) return <TicketModel>[];

      final tickets = <TicketModel>[];
      for (final orderRow in ordersList) {
        final orderMap = Map<String, dynamic>.from(orderRow as Map);
        final eventId = parseString(orderMap['event_id']);
        if (eventId == null) continue;
        final eventRes = await _client.from('events').select('*').eq('id', eventId).maybeSingle();
        if (eventRes == null) continue;
        final eventDetail = await getEventDetail(eventId);
        final ticketsList = orderMap['tickets'];
        if (ticketsList is List) {
          for (final t in ticketsList) {
            final tm = Map<String, dynamic>.from(t as Map);
            final etId = parseString(tm['event_ticket_id']);
            if (etId == null) continue;
            final etRes = await _client.from('event_tickets').select('*').eq('id', etId).maybeSingle();
            final price = etRes is Map<String, dynamic> ? parseDouble(etRes['price']) ?? 0.0 : 0.0;
            final name = etRes is Map<String, dynamic> ? parseStringRequired(etRes['name']) : 'Ticket';
            tickets.add(TicketModel(
              id: parseStringRequired(tm['id']),
              ticketId: parseStringRequired(tm['id']),
              event: eventDetail,
              ticketTypeName: name,
              price: price,
              purchaseDate: parseTimestampRequired(orderMap['created_at']),
              isVerified: false,
              qrCode: null,
            ));
          }
        }
      }
      return tickets;
    });
  }

  @override
  Future<TicketModel> getTicketDetail(String ticketId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client.from('tickets').select('*, orders!inner(*), event_tickets(*), events(*)').eq('id', ticketId).maybeSingle();
      if (res == null) throw Exception('Ticket not found');
      final row = Map<String, dynamic>.from(res as Map);
      final orderId = parseStringRequired(row['order_id']);
      final orderRes = await _client.from('orders').select('*').eq('id', orderId).maybeSingle();
      final eventId = orderRes is Map<String, dynamic> ? parseString(orderRes['event_id']) : null;
      if (eventId == null) throw Exception('Event not found');
      final eventDetail = await getEventDetail(eventId);
      final et = row['event_tickets'];
      final price = et is Map<String, dynamic> ? parseDouble(et['price']) ?? 0.0 : 0.0;
      final name = et is Map<String, dynamic> ? parseStringRequired(et['name']) : 'Ticket';
      return TicketModel(
        id: parseStringRequired(row['id']),
        ticketId: parseStringRequired(row['id']),
        event: eventDetail,
        ticketTypeName: name,
        price: price,
        purchaseDate: parseTimestampRequired(row['created_at']),
        isVerified: false,
        qrCode: null,
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
      num totalAmount = 0;
      final selectedTickets = <SelectedTicket>[];
      for (final t in tickets) {
        final ticketTypeId = (t['ticket_type_id'] ?? t['event_ticket_id']) as String?;
        if (ticketTypeId == null) continue;
        final qty = (t['quantity'] as num?)?.toInt() ?? 1;
        final etRes = await _client.from('event_tickets').select('*').eq('id', ticketTypeId).maybeSingle();
        if (etRes is Map<String, dynamic>) {
          final price = parseDouble(etRes['price']) ?? 0;
          final name = parseStringRequired(etRes['name']);
          totalAmount += price * qty;
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

      final orderRes = await _client.from('orders').insert({
        'user_id': userId,
        'type': 'event',
        'event_id': eventId,
        'status': 'pending',
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

      final serviceFee = 0.0;
      return OrderModel(
        id: orderId,
        event: eventDetail,
        tickets: selectedTickets,
        subtotal: totalAmount.toDouble(),
        serviceFee: serviceFee,
        total: totalAmount.toDouble() + serviceFee,
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
      await _client.from('orders').update({
        'status': 'completed',
        'payment_method': paymentMethod['type'] ?? 'card',
        'payment_id': paymentMethod['id'] ?? '',
      }).eq('id', orderId);

      final res = await _client.from('orders').select('*').eq('id', orderId).single();
      final row = Map<String, dynamic>.from(res as Map);
      final eventId = parseString(row['event_id']);
      if (eventId == null) throw Exception('Order not found');
      final eventDetail = await getEventDetail(eventId);
      return OrderModel(
        id: orderId,
        event: eventDetail,
        tickets: const [],
        subtotal: parseDouble(row['total_amount']) ?? 0,
        serviceFee: 0,
        total: parseDouble(row['total_amount']) ?? 0,
        createdAt: parseTimestampRequired(row['created_at']),
        status: events_domain.OrderStatus.completed,
      );
    });
  }
}
