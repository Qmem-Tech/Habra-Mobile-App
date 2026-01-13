import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import 'package:dartz/dartz.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.login(email, password);
        await localDataSource.cacheUser(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, User>> loginAsGuest() async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.loginAsGuest();
        await localDataSource.cacheUser(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCache();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> register(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.register(
          email,
          password,
          name,
          role,
        );
        await localDataSource.cacheUser(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }
}
