import '../../models/event_model.dart';
import '../../models/deal_model.dart';
import '../../models/business_model.dart';
import '../../models/job_model.dart';

class MockHomeData {
  static List<EventModel> getMockEvents(String location) {
    final now = DateTime.now();
    return [
      EventModel(
        id: '1',
        title: 'Rophnan Concert - VI',
        description: 'Live concert featuring Rophnan',
        imageUrl: 'https://picsum.photos/400/300?random=1',
        dateTime: now.add(const Duration(days: 3)),
        location: location,
        venue: 'Sidist-VI',
        price: 25.00,
        organizer: 'Event Organizer',
      ),
      EventModel(
        id: '2',
        title: 'Nafkot Consert',
        description: 'Ethiopian traditional music concert',
        imageUrl: 'https://picsum.photos/400/300?random=2',
        dateTime: now.add(const Duration(days: 5)),
        location: location,
        venue: 'Ramada Addis',
        price: 30.00,
        organizer: 'Aster Rufe',
      ),
      EventModel(
        id: '3',
        title: 'Ethiopian Food Festival',
        description: 'Celebrate Ethiopian cuisine',
        imageUrl: 'https://picsum.photos/400/300?random=3',
        dateTime: now.add(const Duration(days: 7)),
        location: location,
        venue: 'Community Center',
        price: 15.00,
      ),
      EventModel(
        id: '4',
        title: 'Jazz Night at Fendika',
        description: 'Live Ethio-Jazz performance',
        imageUrl: 'https://picsum.photos/400/300?random=4',
        dateTime: now.add(const Duration(days: 2)),
        location: location,
        venue: 'Fendika Cultural Center',
        price: 20.00,
      ),
    ];
  }

  static List<DealModel> getMockDeals(String location) {
    return [
      DealModel(
        id: '1',
        title: 'Queen of Sheba',
        description: 'Dinner special for two',
        imageUrl: 'https://picsum.photos/200/200?random=5',
        businessName: 'Queen of Sheba Restaurant',
        businessId: 'b1',
        discountPercent: 20.0,
        promoCode: 'DINNER20',
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      ),
      DealModel(
        id: '2',
        title: 'Buna Cafe Special',
        description: '20% off all traditional breakfast items',
        imageUrl: 'https://picsum.photos/200/200?random=6',
        businessName: 'Buna Cafe',
        businessId: 'b2',
        discountPercent: 20.0,
        expiryDate: DateTime.now().add(const Duration(days: 3)),
      ),
      DealModel(
        id: '3',
        title: 'Habesha Market Sale',
        description: 'Fresh spices arrived today',
        imageUrl: 'https://picsum.photos/200/200?random=7',
        businessName: 'Habesha Market',
        businessId: 'b3',
        discountPercent: 15.0,
      ),
    ];
  }

  static List<BusinessModel> getMockBusinesses(String location) {
    return [
      BusinessModel(
        id: 'b1',
        name: 'Blue Nile Cafe',
        category: 'Coffee & Breakfast',
        imageUrl: 'https://picsum.photos/200/200?random=8',
        rating: 4.8,
        reviewCount: 120,
        distance: 0.2,
        priceRange: '\$',
        status: 'Open now',
        isVerified: true,
      ),
      BusinessModel(
        id: 'b2',
        name: 'Habesha Law Firm',
        category: 'Legal Services',
        imageUrl: 'https://picsum.photos/200/200?random=9',
        rating: 5.0,
        reviewCount: 45,
        distance: 1.5,
        priceRange: '\$\$',
        isVerified: true,
      ),
      BusinessModel(
        id: 'b3',
        name: 'Sheba Lounge',
        category: 'Restaurant',
        imageUrl: 'https://picsum.photos/200/200?random=10',
        rating: 4.8,
        reviewCount: 120,
        distance: 0.8,
        priceRange: '\$\$',
        status: '10% off Lunch Buffet',
        isVerified: true,
      ),
      BusinessModel(
        id: 'b4',
        name: 'Habesha Market',
        category: 'Grocery',
        imageUrl: 'https://picsum.photos/200/200?random=11',
        rating: 4.5,
        reviewCount: 45,
        distance: 2.1,
        priceRange: '\$',
        status: 'Fresh spices arrived today',
        isVerified: false,
      ),
    ];
  }

  static List<JobModel> getMockJobs(String location) {
    return [
      JobModel(
        id: 'j1',
        title: 'Sous Chef',
        companyName: 'Desta Kitchen',
        companyId: 'b5',
        jobType: 'Full-time',
        description: 'Looking for experienced sous chef for Ethiopian restaurant',
        location: location,
        salary: '\$45,000 - \$55,000/year',
        postedDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      JobModel(
        id: 'j2',
        title: 'Store Manager',
        companyName: 'Merkato Grocery',
        companyId: 'b6',
        jobType: 'Part-time',
        description: 'Part-time store manager position available',
        location: location,
        salary: '\$20/hour',
        postedDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      JobModel(
        id: 'j3',
        title: 'Wait Staff',
        companyName: 'Queen of Sheba',
        companyId: 'b1',
        jobType: 'Part-time',
        description: 'Experienced wait staff needed',
        location: location,
        salary: '\$15/hour + tips',
        postedDate: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }
}
