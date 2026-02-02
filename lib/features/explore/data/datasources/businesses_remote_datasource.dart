import '../../domain/entities/business_list_item.dart';
import '../../domain/entities/business_detail.dart';
import '../../domain/entities/business_filters.dart';
import '../../domain/entities/business_category.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/review.dart';
import '../models/review_model.dart';
import 'mock_data/mock_businesses_data.dart';

abstract class BusinessesRemoteDataSource {
  Future<List<BusinessListItem>> getBusinesses({
    String? location,
    BusinessFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  });

  Future<BusinessDetail> getBusinessDetail(String businessId);

  Future<List<Deal>> getDeals({
    String? location,
    String? category,
    DealType? dealType,
  });

  Future<Deal> getDealDetail(String dealId);

  Future<List<Review>> getBusinessReviews(String businessId);

  Future<Review> writeReview({
    required String businessId,
    required int rating,
    required String comment,
    List<String>? photoUrls,
  });

  Future<String> redeemDeal(String dealId);
}

class BusinessesRemoteDataSourceImpl implements BusinessesRemoteDataSource {
  @override
  Future<List<BusinessListItem>> getBusinesses({
    String? location,
    BusinessFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    BusinessCategory? category;
    if (filters?.category != null) {
      category = filters!.category;
    }

    final businesses = MockBusinessesData.getMockBusinesses(
      location: location,
      category: category,
      searchQuery: searchQuery,
      featuredOnly: featuredOnly,
    );

    // Apply additional filters
    var filtered = businesses;
    if (filters != null) {
      if (filters.minRating != null) {
        filtered = filtered
            .where((b) => b.rating >= filters.minRating!)
            .toList();
      }
      if (filters.priceRange != null) {
        filtered = filtered
            .where((b) => b.priceRange == filters.priceRange)
            .toList();
      }
      if (filters.isOpenNow != null && filters.isOpenNow!) {
        filtered = filtered.where((b) => b.isOpen).toList();
      }
      if (filters.isVerified != null && filters.isVerified!) {
        filtered = filtered.where((b) => b.isVerified).toList();
      }
    }

    return filtered;
  }

  @override
  Future<BusinessDetail> getBusinessDetail(String businessId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockBusinessesData.getBusinessDetail(businessId);
  }

  @override
  Future<List<Deal>> getDeals({
    String? location,
    String? category,
    DealType? dealType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockBusinessesData.getMockDeals(
      location: location,
      category: category,
      dealType: dealType,
    );
  }

  @override
  Future<Deal> getDealDetail(String dealId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockBusinessesData.getDealDetail(dealId);
  }

  @override
  Future<List<Review>> getBusinessReviews(String businessId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockBusinessesData.getMockReviews(businessId);
  }

  @override
  Future<Review> writeReview({
    required String businessId,
    required int rating,
    required String comment,
    List<String>? photoUrls,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Simulate creating a new review
    return ReviewModel(
      id: 'review_new_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current_user',
      userName: 'You',
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      photoUrls: photoUrls,
      isVerified: false,
    );
  }

  @override
  Future<String> redeemDeal(String dealId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final deal = await getDealDetail(dealId);
    return deal.redemptionCode ?? 'HAB-${DateTime.now().millisecondsSinceEpoch}';
  }
}
