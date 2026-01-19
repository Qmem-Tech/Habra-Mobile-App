import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/business_list_item.dart';
import '../../domain/entities/business_detail.dart';
import '../../domain/entities/business_filters.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/businesses_repository.dart';
import '../datasources/businesses_remote_datasource.dart';

class BusinessesRepositoryImpl implements BusinessesRepository {
  final BusinessesRemoteDataSource remoteDataSource;

  BusinessesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<BusinessListItem>>> getBusinesses({
    String? location,
    BusinessFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  }) async {
    try {
      final businesses = await remoteDataSource.getBusinesses(
        location: location,
        filters: filters,
        searchQuery: searchQuery,
        featuredOnly: featuredOnly,
      );
      return Right(businesses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BusinessDetail>> getBusinessDetail(
      String businessId) async {
    try {
      final business = await remoteDataSource.getBusinessDetail(businessId);
      return Right(business);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Deal>>> getDeals({
    String? location,
    String? category,
    DealType? dealType,
  }) async {
    try {
      final deals = await remoteDataSource.getDeals(
        location: location,
        category: category,
        dealType: dealType,
      );
      return Right(deals);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Deal>> getDealDetail(String dealId) async {
    try {
      final deal = await remoteDataSource.getDealDetail(dealId);
      return Right(deal);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Review>>> getBusinessReviews(
      String businessId) async {
    try {
      final reviews = await remoteDataSource.getBusinessReviews(businessId);
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Review>> writeReview({
    required String businessId,
    required int rating,
    required String comment,
    List<String>? photoUrls,
  }) async {
    try {
      final review = await remoteDataSource.writeReview(
        businessId: businessId,
        rating: rating,
        comment: comment,
        photoUrls: photoUrls,
      );
      return Right(review);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> redeemDeal(String dealId) async {
    try {
      final code = await remoteDataSource.redeemDeal(dealId);
      return Right(code);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
