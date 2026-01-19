import '../../../domain/entities/business_list_item.dart';
import '../../../domain/entities/business_detail.dart';
import '../../../domain/entities/deal.dart';
import '../../../domain/entities/review.dart';
import '../../../domain/entities/business_category.dart';
import '../../models/business_list_item_model.dart';
import '../../models/deal_model.dart';
import '../../models/review_model.dart';

class MockBusinessesData {
  // Available business images - will be rotated
  static const List<String> businessImages = [
    'assets/images/businesses/cultural_night_hero.png',
    'assets/images/businesses/cultural_night.png',
    'assets/images/businesses/teddy_afro_concert.png',
  ];

  // Available deal images - will be rotated
  static const List<String> dealImages = [
    'assets/images/deals/cultural_night_hero.png',
    'assets/images/deals/cultural_night.png',
    'assets/images/deals/teddy_afro_concert.png',
  ];

  static String _getBusinessImage(int index) {
    return businessImages[index % businessImages.length];
  }

  static String _getDealImage(int index) {
    return dealImages[index % dealImages.length];
  }

  static List<BusinessListItemModel> getMockBusinesses({
    String? location,
    BusinessCategory? category,
    String? searchQuery,
    bool featuredOnly = false,
  }) {
    final businesses = <BusinessListItemModel>[
      BusinessListItemModel(
        id: 'business_1',
        name: 'Habesha Market',
        imageUrl: _getBusinessImage(0),
        categories: [BusinessCategory.grocery, BusinessCategory.import],
        address: '1920 9th St NW',
        city: 'Washington',
        state: 'DC',
        distance: 0.8,
        rating: 4.8,
        reviewCount: 120,
        priceRange: '\$\$',
        isVerified: true,
        isOpen: true,
        closingTime: '10 PM',
        isFeatured: true,
      ),
      BusinessListItemModel(
        id: 'business_2',
        name: 'Addis Cafe',
        imageUrl: _getBusinessImage(1),
        categories: [BusinessCategory.cafe, BusinessCategory.food],
        address: '2400 1st St NW',
        city: 'Washington',
        state: 'DC',
        distance: 1.2,
        rating: 4.9,
        reviewCount: 89,
        priceRange: '\$',
        isVerified: true,
        isOpen: true,
        closingTime: '8 PM',
        isFeatured: true,
      ),
      BusinessListItemModel(
        id: 'business_3', 
        name: 'Sheba Restaurant',
        imageUrl: _getBusinessImage(2),
        categories: [BusinessCategory.restaurant, BusinessCategory.food],
        address: '1234 Georgia Ave NW',
        city: 'Washington',
        state: 'DC',
        distance: 0.8,
        rating: 4.7,
        reviewCount: 128,
        priceRange: '\$\$',
        isVerified: true,
        isOpen: true,
        closingTime: '10 PM',
        isFeatured: false,
      ),
      BusinessListItemModel(
        id: 'business_4',
        name: 'Merkato Grocery',
        imageUrl: _getBusinessImage(0),
        categories: [BusinessCategory.grocery],
        address: '5678 14th St NW',
        city: 'Washington',
        state: 'DC',
        distance: 2.1,
        rating: 4.5,
        reviewCount: 42,
        priceRange: '\$\$',
        isVerified: false,
        isOpen: false,
        openingTime: '9 AM',
        isFeatured: false,
      ),
      BusinessListItemModel(
        id: 'business_5',
        name: 'Lalibela Salon',
        imageUrl: _getBusinessImage(1),
        categories: [BusinessCategory.beauty, BusinessCategory.salon],
        address: '9012 U St NW',
        city: 'Washington',
        state: 'DC',
        distance: 3.4,
        rating: 5.0,
        reviewCount: 15,
        priceRange: '\$\$\$',
        isVerified: true,
        isOpen: true,
        closingTime: '8 PM',
        isFeatured: false,
      ),
      BusinessListItemModel(
        id: 'business_6',
        name: 'Taste of Habesha',
        imageUrl: _getBusinessImage(2),
        categories: [BusinessCategory.restaurant, BusinessCategory.food],
        address: '3456 Columbia Rd NW',
        city: 'Washington',
        state: 'DC',
        distance: 5.0,
        rating: 4.2,
        reviewCount: 89,
        priceRange: '\$\$',
        isVerified: false,
        isOpen: true,
        closingTime: '11 PM',
        isFeatured: false,
      ),
      BusinessListItemModel(
        id: 'business_7',
        name: 'Blue Nile Kitchen',
        imageUrl: _getBusinessImage(0),
        categories: [BusinessCategory.restaurant, BusinessCategory.food],
        address: '7890 18th St NW',
        city: 'Washington',
        state: 'DC',
        distance: 1.2,
        rating: 4.9,
        reviewCount: 156,
        priceRange: '\$\$',
        isVerified: true,
        isOpen: true,
        closingTime: '9 PM',
        isFeatured: true,
      ),
      BusinessListItemModel(
        id: 'business_8',
        name: 'Lion Barbershop',
        imageUrl: _getBusinessImage(1),
        categories: [BusinessCategory.barbershop, BusinessCategory.beauty],
        address: '4567 7th St NW',
        city: 'Washington',
        state: 'DC',
        distance: 0.5,
        rating: 4.6,
        reviewCount: 67,
        priceRange: '\$\$',
        isVerified: false,
        isOpen: true,
        closingTime: '7 PM',
        isFeatured: false,
      ),
    ];

    var filtered = businesses;

    // Filter by featured
    if (featuredOnly) {
      filtered = filtered.where((b) => b.isFeatured).toList();
    }

    // Filter by category
    if (category != null && category != BusinessCategory.all) {
      filtered = filtered.where((b) {
        return b.categories.contains(category);
      }).toList();
    }

    // Filter by search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((b) {
        return b.name.toLowerCase().contains(query) ||
            b.address.toLowerCase().contains(query) ||
            b.categories.any((c) => c.displayName.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  static BusinessDetail getBusinessDetail(String businessId) {
    final now = DateTime.now();

    if (businessId == 'business_7' || businessId == 'blue_nile_kitchen') {
      return BusinessDetail(
        id: 'business_7',
        name: 'Blue Nile Kitchen',
        description:
            'Authentic Ethiopian cuisine in the heart of the city. We serve traditional Ethiopian dishes prepared with fresh, locally sourced ingredients. Our Kitfo and Doro Wat are town favorites. Come experience our warm hospitality.',
        imageUrls: [
          _getBusinessImage(0),
          _getBusinessImage(1),
        ],
        categories: [BusinessCategory.restaurant, BusinessCategory.food],
        address: '7890 18th St NW',
        city: 'Washington',
        state: 'DC',
        zipCode: '20011',
        latitude: 38.9072,
        longitude: -77.0369,
        phoneNumber: '+1 (202) 555-0123',
        website: 'https://bluenilekitchen.com',
        rating: 4.9,
        reviewCount: 156,
        priceRange: '\$\$',
        isVerified: true,
        isOpen: true,
        closingTime: '9 PM',
        hours: [
          'Mon-Fri: 11 AM - 9 PM',
          'Sat-Sun: 12 PM - 10 PM',
        ],
        currentDeals: [
          Deal(
            id: 'deal_1',
            title: 'Lunch Special: 20% Off',
            description:
                'Order any veggie combo between 11 AM - 2 PM and get a free soft drink.',
            imageUrl: _getDealImage(0),
            business: getMockBusinesses()[6] as BusinessListItem,
            type: DealType.hotDeal,
            discountText: '20% Off',
            validDays: 'Mon-Fri',
            validTime: '11 AM - 2 PM',
            dealDetails: [
              'Valid Monday through Friday only.',
              'Dine-in only. Not valid for takeout or delivery.',
              'One coupon per table. Cannot be combined.',
            ],
          ),
        ],
        reviews: getMockReviews('business_7'),
        similarBusinesses: [
          getMockBusinesses()[2], // Sheba Restaurant
          getMockBusinesses()[5], // Taste of Habesha
        ],
        photos: [
          _getBusinessImage(0),
          _getBusinessImage(1),
        ],
      );
    }

    // Default business detail
    return BusinessDetail(
      id: businessId,
      name: 'Addis Ababa Restaurant',
      description:
          'Authentic Habesha flavors in the heart of the city. We serve traditional Ethiopian dishes prepared with fresh, locally sourced ingredients. Our Kitfo and Doro Wat are town favorites. Come experience our warm hospitality.',
      imageUrls: [
        _getBusinessImage(2),
      ],
      categories: [BusinessCategory.restaurant, BusinessCategory.food],
      address: '1234 Little Ethiopia Ave',
      city: 'Los Angeles',
      state: 'CA',
      zipCode: '90035',
      latitude: 34.0522,
      longitude: -118.2437,
      phoneNumber: '+1 (213) 555-0123',
      rating: 4.8,
      reviewCount: 120,
      priceRange: '\$\$',
      isVerified: true,
      isOpen: true,
      closingTime: '10 PM',
      hours: [
        'Mon-Thu: 11 AM - 10 PM',
        'Fri-Sat: 11 AM - 11 PM',
        'Sun: 12 PM - 9 PM',
      ],
      currentDeals: [
        Deal(
          id: 'deal_2',
          title: 'Lunch Special: 20% Off',
          description:
              'Order any veggie combo between 11 AM - 2 PM and get a free soft drink.',
          imageUrl: _getDealImage(1),
          business: getMockBusinesses()[1] as BusinessListItem,
          type: DealType.hotDeal,
          discountText: '20% Off',
          validDays: 'Mon-Fri',
          validTime: '11 AM - 2 PM',
        ),
      ],
      reviews: getMockReviews(businessId),
      similarBusinesses: getMockBusinesses().take(2).toList(),
      photos: [
        _getBusinessImage(2),
      ],
    );
  }

  static List<DealModel> getMockDeals({
    String? location,
    String? category,
    DealType? dealType,
  }) {
    final businesses = getMockBusinesses();
    final now = DateTime.now();

    // Convert to BusinessListItem for deals
    final businessList = businesses.map((b) => b as BusinessListItem).toList();

    final deals = <DealModel>[
      DealModel(
        id: 'deal_1',
        title: 'Buy 1 Get 1 Buna',
        description: 'Buy one coffee, get one free on your first visit.',
        imageUrl: _getDealImage(0),
        business: businessList[1], // Addis Cafe
        type: DealType.hotDeal,
        discountText: 'Buy 1 Get 1 Free',
        expiresAt: now.add(const Duration(days: 2)),
        isRedeemable: true,
      ),
      DealModel(
        id: 'deal_2',
        title: 'First Visit Discount',
        description: 'Get 20% off on your first visit.',
        imageUrl: _getDealImage(1),
        business: businessList[7], // Lion Barbershop
        type: DealType.hotDeal,
        discountText: '20% Off',
        expiresAt: now.add(const Duration(days: 7)),
        isRedeemable: true,
      ),
      DealModel(
        id: 'deal_3',
        title: '50% Off Drinks',
        description: 'Happy hour specials on all drinks.',
        imageUrl: _getDealImage(2),
        business: businessList[1], // Addis Cafe
        type: DealType.happyHour,
        discountText: '50% Off',
        validDays: 'Mon-Fri',
        validTime: '5-7 PM',
        isRedeemable: false,
      ),
      DealModel(
        id: 'deal_4',
        title: 'Free Cookie w/ Tea',
        description: 'Get a free cookie with any tea purchase.',
        imageUrl: _getDealImage(0),
        business: businessList[1], // Addis Cafe
        type: DealType.happyHour,
        discountText: 'Free Cookie',
        validTime: 'Until 8 PM',
        isRedeemable: false,
      ),
      DealModel(
        id: 'deal_5',
        title: 'Spicy Doro Wat Combo',
        description:
            'Experience the authentic taste of Ethiopia with our signature Spicy Doro Wat Combo. This platter serves one and includes: Slow-cooked chicken stew (Doro Wat), Hard-boiled egg marinated in sauce, Side of homemade cottage cheese (Ayib), Unlimited fresh Injera',
        imageUrl: _getDealImage(1),
        business: businessList[0], // Habesha Market
        type: DealType.limitedTime,
        originalPrice: 20.0,
        discountedPrice: 10.0,
        discountText: '50% Off',
        expiresAt: now.add(const Duration(days: 2, hours: 14, minutes: 35)),
        dealDetails: [
          'Slow-cooked chicken stew (Doro Wat)',
          'Hard-boiled egg marinated in sauce',
          'Side of homemade cottage cheese (Ayib)',
          'Unlimited fresh Injera',
        ],
        termsAndConditions:
            'Valid Monday through Friday only. Dine-in only. Not valid for takeout or delivery. One coupon per table. Cannot be combined.',
        isRedeemable: true,
      ),
    ];

    var filtered = deals;

    // Filter by deal type
    if (dealType != null) {
      filtered = filtered.where((d) => d.type == dealType).toList();
    }

    return filtered;
  }

  static DealModel getDealDetail(String dealId) {
    final deals = getMockDeals();
    final deal = deals.firstWhere(
      (d) => d.id == dealId,
      orElse: () => deals.first,
    );

    // Return a copy with redemption code
    return DealModel(
      id: deal.id,
      title: deal.title,
      description: deal.description,
      imageUrl: deal.imageUrl,
      business: deal.business,
      type: deal.type,
      originalPrice: deal.originalPrice,
      discountedPrice: deal.discountedPrice,
      discountText: deal.discountText,
      expiresAt: deal.expiresAt,
      termsAndConditions: deal.termsAndConditions,
      dealDetails: deal.dealDetails,
      redemptionCode: 'HAB-882-XJ',
      isRedeemable: deal.isRedeemable,
      validDays: deal.validDays,
      validTime: deal.validTime,
    );
  }

  static List<ReviewModel> getMockReviews(String businessId) {
    final now = DateTime.now();
    return [
      ReviewModel(
        id: 'review_1',
        userId: 'user_1',
        userName: 'Sarah M.',
        rating: 5,
        comment:
            'Best kitfo in town! Highly recommend. The atmosphere is very cozy and the staff are super friendly. Will definitely come back for the coffee ceremony.',
        createdAt: now.subtract(const Duration(days: 2)),
        isVerified: true,
      ),
      ReviewModel(
        id: 'review_2',
        userId: 'user_2',
        userName: 'Michael T.',
        rating: 4,
        comment:
            'Great food and service. The Doro Wat was excellent. Only downside was the wait time during peak hours.',
        createdAt: now.subtract(const Duration(days: 5)),
        isVerified: false,
      ),
      ReviewModel(
        id: 'review_3',
        userId: 'user_3',
        userName: 'Alem K.',
        rating: 5,
        comment:
            'Authentic Ethiopian flavors! Reminds me of home. The injera is fresh and the portions are generous.',
        createdAt: now.subtract(const Duration(days: 7)),
        isVerified: true,
      ),
    ];
  }

  static List<BusinessListItemModel> getSimilarBusinesses(String businessId) {
    final businesses = getMockBusinesses();
    return businesses.where((b) => b.id != businessId).take(2).toList();
  }
}
