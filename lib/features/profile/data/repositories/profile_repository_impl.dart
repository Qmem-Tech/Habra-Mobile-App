import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserProfile>> getProfile(String userId) async {
    try {
      final profile = await remoteDataSource.getProfile(userId);
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile(
      String userId, UserProfileUpdate update) async {
    try {
      final profile = await remoteDataSource.updateProfile(userId, update);
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
