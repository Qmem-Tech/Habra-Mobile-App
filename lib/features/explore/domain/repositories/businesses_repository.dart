import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/business_list_item.dart';
import '../entities/business_detail.dart';
import '../entities/business_filters.dart';
import '../entities/deal.dart';
import '../entities/deal_redemption.dart';
import '../entities/my_review.dart';
import '../entities/review.dart';

abstract class BusinessesRepository {
  Future<Either<Failure, List<BusinessListItem>>> getBusinesses({
    String? location,
    BusinessFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  });

  Future<Either<Failure, BusinessDetail>> getBusinessDetail(String businessId);

  Future<Either<Failure, List<Deal>>> getDeals({
    String? location,
    String? category,
    DealType? dealType,
  });

  Future<Either<Failure, Deal>> getDealDetail(String dealId);

  Future<Either<Failure, List<Review>>> getBusinessReviews(String businessId);

  Future<Either<Failure, Review>> writeReview({
    required String businessId,
    required int rating,
    required String comment,
    List<String>? photoUrls,
  });

  Future<Either<Failure, DealRedemption>> redeemDeal(String dealId);

  Future<Either<Failure, List<MyReview>>> getMyReviews();
  Future<Either<Failure, MyReview>> updateReview(String reviewId, {int? rating, String? comment});
  Future<Either<Failure, void>> deleteReview(String reviewId);

  /// Best-effort analytics ping when a listing is opened; never surfaces [Failure] to callers.
  Future<void> recordBusinessListingView(String businessId);
}
