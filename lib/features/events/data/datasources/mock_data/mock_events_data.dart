import '../../models/event_list_item_model.dart';
import '../../models/event_detail_model.dart';
import '../../models/ticket_type_model.dart';
import '../../models/ticket_model.dart';
import '../../models/order_model.dart';
import '../../../domain/entities/event_category.dart';
import '../../../domain/entities/ticket_type.dart';
import '../../../domain/entities/event_detail.dart';
import '../../../domain/entities/ticket.dart';
import '../../../domain/entities/order.dart' as events;
import '../../../domain/entities/selected_ticket.dart';

class MockEventsData {
  static List<EventListItemModel> getMockEvents({
    String? location,
    List<EventCategory>? categories,
    String? searchQuery,
  }) {
    final now = DateTime.now();
    // Available images: teddy_afro_concert.png, cultural_night.png, cultural_night_hero.png
    final events = <EventListItemModel>[
      EventListItemModel(
        id: 'event_1',
        title: 'Teddy Afro Live in Seattle',
        imageUrl: 'assets/images/events/teddy_afro_concert.png',
        categories: [EventCategory.music, EventCategory.cultural],
        dateTime: DateTime(now.year, now.month, 5, 10, 0),
        venue: 'Showbox SoDo',
        location: location ?? 'Seattle, WA',
        price: 20.0,
        isBookmarked: false,
      ),
      EventListItemModel(
        id: 'event_2',
        title: 'Teddy Afro Live in Seattle',
        imageUrl: 'assets/images/events/cultural_night.png',
        categories: [EventCategory.music, EventCategory.cultural],
        dateTime: DateTime(now.year, now.month, 5, 10, 0),
        venue: 'Showbox SoDo',
        location: location ?? 'Seattle, WA',
        price: 20.0,
        isBookmarked: false,
      ),
      EventListItemModel(
        id: 'event_3',
        title: 'Teddy Afro Live in Seattle',
        imageUrl: 'assets/images/events/cultural_night_hero.png',
        categories: [EventCategory.music, EventCategory.cultural],
        dateTime: DateTime(now.year, now.month, 5, 10, 0),
        venue: 'Showbox SoDo',
        location: location ?? 'Seattle, WA',
        priceRange: '\$45 - \$120',
        isBookmarked: false,
      ),
      EventListItemModel(
        id: 'event_4',
        title: 'Habesha Cultural Night 2024',
        imageUrl: 'assets/images/events/cultural_night.png',
        categories: [EventCategory.cultural, EventCategory.community],
        dateTime: DateTime(now.year, 12, 12, 20, 0),
        venue: 'Addis Ababa Hall',
        location: location ?? 'Washington, DC',
        price: 45.0,
        isBookmarked: false,
      ),
      EventListItemModel(
        id: 'event_5',
        title: 'Ethio-Jazz Night',
        imageUrl: 'assets/images/events/teddy_afro_concert.png',
        categories: [EventCategory.music, EventCategory.nightlife],
        dateTime: DateTime(now.year, now.month + 1, 15, 19, 0),
        venue: 'Howard Theatre',
        location: location ?? 'Washington, DC',
        price: 30.0,
        isBookmarked: false,
      ),
      EventListItemModel(
        id: 'event_6',
        title: 'Coffee Ceremony',
        imageUrl: 'assets/images/events/cultural_night_hero.png',
        categories: [EventCategory.cultural, EventCategory.community],
        dateTime: DateTime(now.year, now.month + 1, 20, 14, 0),
        venue: 'Sidamo Coffee & Tea',
        location: location ?? 'Washington, DC',
        price: 15.0,
        isBookmarked: false,
      ),
    ];

    // Apply filters
    var filtered = events;
    if (categories != null && categories.isNotEmpty && !categories.contains(EventCategory.all)) {
      filtered = filtered.where((e) {
        return e.categories.any((c) => categories.contains(c));
      }).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.venue.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  static EventDetailModel getEventDetail(String eventId) {
    final now = DateTime.now();

    if (eventId == 'event_4' || eventId == 'habesha_cultural_night') {
      return EventDetailModel(
        id: 'event_4',
        title: 'Habesha Cultural Night 2024',
        description: 'Celebrate the Ethiopian New Year with us at the biggest cultural gathering in DC! Experience live performances from top artists, traditional food vendors, art exhibitions, and a vibrant community atmosphere. This year we are featuring special guest performances and a dedicated cultural dance showcase.',
        imageUrl: 'assets/images/events/cultural_night_hero.png',
        categories: [EventCategory.cultural, EventCategory.community],
        startDate: DateTime(now.year, 12, 12, 18, 0),
        endDate: DateTime(now.year, 12, 12, 23, 30),
        venue: 'Addis Hall',
        address: '1234 Georgia Ave NW',
        city: 'Washington',
        state: 'DC',
        zipCode: '20001',
        latitude: 38.9072,
        longitude: -77.0369,
        minPrice: 45.0,
        maxPrice: 200.0,
        organizer: 'Habesha Community App',
        ticketTypes: [
          TicketTypeModel(
            id: 'ticket_1',
            name: 'General Admission',
            description: 'Standard entry to the main hall.',
            price: 25.0,
            status: TicketStatus.available,
            availableQuantity: 100,
            icon: 'ticket',
          ),
          TicketTypeModel(
            id: 'ticket_2',
            name: 'VIP Access',
            description: 'Front row access + 1 free drink',
            price: 55.0,
            status: TicketStatus.lowStock,
            availableQuantity: 4,
            icon: 'star',
          ),
          TicketTypeModel(
            id: 'ticket_3',
            name: 'VVIP Table',
            description: 'Private table for 4 with bottle service.',
            price: 200.0,
            status: TicketStatus.soldOut,
            availableQuantity: 0,
            icon: 'table',
          ),
        ],
        isBookmarked: false,
        policies: [
          '21+ Event. ID Required for entry.',
          'No Refunds or Exchanges.',
          'Doors close strictly at 10 PM.',
        ],
      );
    }

    // Default event detail
    return EventDetailModel(
      id: eventId,
      title: 'Teddy Afro Live in Seattle',
      description: 'Join us for an unforgettable night with Teddy Afro, one of Ethiopia\'s most celebrated artists. Experience the energy and passion of live Ethiopian music in an intimate setting.',
      imageUrl: 'assets/images/events/teddy_afro_concert.png',
      categories: [EventCategory.music, EventCategory.cultural],
      startDate: DateTime(now.year, now.month, 5, 10, 0),
      endDate: DateTime(now.year, now.month, 5, 14, 0),
      venue: 'Showbox SoDo',
      address: '1700 1st Ave S',
      city: 'Seattle',
      state: 'WA',
      zipCode: '98134',
      latitude: 47.6062,
      longitude: -122.3321,
      minPrice: 20.0,
      maxPrice: 120.0,
      organizer: 'Event Organizer',
      ticketTypes: [
        TicketTypeModel(
          id: 'ticket_1',
          name: 'General Admission',
          description: 'Standard entry ticket',
          price: 20.0,
          status: TicketStatus.available,
          availableQuantity: 50,
        ),
        TicketTypeModel(
          id: 'ticket_2',
          name: 'VIP',
          description: 'VIP access with premium seating',
          price: 45.0,
          status: TicketStatus.available,
          availableQuantity: 20,
        ),
      ],
      isBookmarked: false,
    );
  }

  static List<EventListItemModel> getSimilarEvents(String eventId) {
    final events = getMockEvents();
    return events.where((e) => e.id != eventId).take(2).toList();
  }

  static List<TicketModel> getUserTickets({bool upcomingOnly = true}) {
    final now = DateTime.now();
    final eventDetail = getEventDetail('event_4');
    final eventDate = DateTime(now.year, 10, 24, 20, 0);

    final tickets = <TicketModel>[
      TicketModel(
        id: 'ticket_user_1',
        ticketId: 'HB-89204',
        event: EventDetailModel(
          id: eventDetail.id,
          title: eventDetail.title,
          description: eventDetail.description,
          imageUrl: eventDetail.imageUrl,
          categories: eventDetail.categories,
          startDate: eventDate,
          endDate: DateTime(now.year, 10, 24, 23, 0),
          venue: eventDetail.venue,
          address: eventDetail.address,
          city: eventDetail.city,
          state: eventDetail.state,
          zipCode: eventDetail.zipCode,
          latitude: eventDetail.latitude,
          longitude: eventDetail.longitude,
          minPrice: eventDetail.minPrice,
          maxPrice: eventDetail.maxPrice,
          organizer: eventDetail.organizer,
          ticketTypes: eventDetail.ticketTypes,
          isBookmarked: eventDetail.isBookmarked,
          policies: eventDetail.policies,
        ),
        ticketTypeName: 'VIP',
        price: 55.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 5)),
        isVerified: true,
        qrCode: 'HB-89204-QR-CODE',
      ),
      TicketModel(
        id: 'ticket_user_2',
        ticketId: 'HB-89205',
        event: EventDetailModel(
          id: eventDetail.id,
          title: eventDetail.title,
          description: eventDetail.description,
          imageUrl: eventDetail.imageUrl,
          categories: eventDetail.categories,
          startDate: eventDate,
          endDate: DateTime(now.year, 10, 24, 23, 0),
          venue: eventDetail.venue,
          address: eventDetail.address,
          city: eventDetail.city,
          state: eventDetail.state,
          zipCode: eventDetail.zipCode,
          latitude: eventDetail.latitude,
          longitude: eventDetail.longitude,
          minPrice: eventDetail.minPrice,
          maxPrice: eventDetail.maxPrice,
          organizer: eventDetail.organizer,
          ticketTypes: eventDetail.ticketTypes,
          isBookmarked: eventDetail.isBookmarked,
          policies: eventDetail.policies,
        ),
        ticketTypeName: 'VIP',
        price: 55.0,
        purchaseDate: DateTime.now().subtract(const Duration(days: 5)),
        isVerified: true,
        qrCode: 'HB-89205-QR-CODE',
      ),
    ];

    if (upcomingOnly) {
      return tickets.where((t) => t.event.startDate.isAfter(now)).toList();
    }
    return tickets;
  }

  static TicketModel getTicketDetail(String ticketId) {
    final tickets = getUserTickets();
    return tickets.firstWhere(
      (t) => t.ticketId == ticketId,
      orElse: () => tickets.first,
    );
  }

  static OrderModel createOrder({
    required String eventId,
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic> contactInfo,
  }) {
    final event = getEventDetail(eventId);
    final now = DateTime.now();

    final selectedTickets = tickets.map((t) {
      final ticketType = event.ticketTypes.firstWhere(
        (tt) => tt.id == t['ticketTypeId'],
      );
      return SelectedTicket(
        ticketType: ticketType,
        quantity: t['quantity'] as int,
      );
    }).toList();

    final subtotal = selectedTickets.fold<double>(
      0.0,
      (sum, ticket) => sum + ticket.totalPrice,
    );
    final serviceFee = subtotal * 0.05; // 5% service fee
    final total = subtotal + serviceFee;

    return OrderModel(
      id: 'order_${now.millisecondsSinceEpoch}',
      event: event,
      tickets: selectedTickets,
      subtotal: subtotal,
      serviceFee: serviceFee,
      total: total,
      createdAt: now,
      status: events.OrderStatus.pending,
    );
  }

  static OrderModel processPayment({
    required String orderId,
    required Map<String, dynamic> paymentMethod,
    String? promoCode,
  }) {
    // Simulate payment processing
    final now = DateTime.now();
    // In real app, this would fetch the order from storage/API
    final order = createOrder(
      eventId: 'event_4',
      tickets: [
        {'ticketTypeId': 'ticket_2', 'quantity': 2},
      ],
      contactInfo: {},
    );

    // Simulate payment success/failure
    final paymentType = paymentMethod['type'] as String?;
    final shouldFail = paymentMethod['cardNumber']?.toString().endsWith('0000') ?? false;

    return OrderModel(
      id: order.id,
      event: order.event,
      tickets: order.tickets,
      subtotal: order.subtotal,
      serviceFee: order.serviceFee,
      total: order.total,
      createdAt: order.createdAt,
      status: shouldFail ? events.OrderStatus.failed : events.OrderStatus.completed,
    );
  }
}
