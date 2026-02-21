import '../../domain/entities/business_list_item.dart';
import '../../domain/entities/business_detail.dart';
import '../../domain/entities/business_filters.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/my_review.dart';
import '../../domain/entities/review.dart';

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

  Future<List<MyReview>> getMyReviews();
  Future<MyReview> updateReview(String reviewId, {int? rating, String? comment});
  Future<void> deleteReview(String reviewId);
}

class BusinessesRemoteDataSourceImpl implements BusinessesRemoteDataSource {
  @override
  Future<List<BusinessListItem>> getBusinesses({
    String? location,
    BusinessFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  }) async {
    return [];
  }

  @override
  Future<BusinessDetail> getBusinessDetail(String businessId) async {
    throw UnimplementedError(
      'Use BusinessesSupabaseDataSource; backend must provide business $businessId',
    );
  }

  @override
  Future<List<Deal>> getDeals({
    String? location,
    String? category,
    DealType? dealType,
  }) async {
    return [];
  }

  @override
  Future<Deal> getDealDetail(String dealId) async {
    throw UnimplementedError(
      'Use BusinessesSupabaseDataSource; backend must provide deal $dealId',
    );
  }

  @override
  Future<List<Review>> getBusinessReviews(String businessId) async {
    return [];
  }

  @override
  Future<Review> writeReview({
    required String businessId,
    required int rating,
    required String comment,
    List<String>? photoUrls,
  }) async {
    throw UnimplementedError(
      'Use BusinessesSupabaseDataSource; backend must handle writeReview.',
    );
  }

  @override
  Future<String> redeemDeal(String dealId) async {
    throw UnimplementedError(
      'Use BusinessesSupabaseDataSource; backend must handle redeemDeal.',
    );
  }

  @override
  Future<List<MyReview>> getMyReviews() async => [];

  @override
  Future<MyReview> updateReview(String reviewId, {int? rating, String? comment}) async {
    throw UnimplementedError('Use BusinessesSupabaseDataSource');
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    throw UnimplementedError('Use BusinessesSupabaseDataSource');
  }
}
