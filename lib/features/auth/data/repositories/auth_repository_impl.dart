import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';
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
      } on EmailVerificationRequiredException catch (e) {
        return Left(EmailVerificationPendingFailure(e.email));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on ForbiddenException catch (e) {
        return Left(ForbiddenFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
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
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on ForbiddenException catch (e) {
        return Left(ForbiddenFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle({
    bool forceAccountPicker = false,
    UserRole? oauthIntendedRole,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.signInWithGoogle(
          forceAccountPicker: forceAccountPicker,
          oauthIntendedRole: oauthIntendedRole,
        );
        await localDataSource.cacheUser(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on ForbiddenException catch (e) {
        return Left(ForbiddenFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithApple({UserRole? oauthIntendedRole}) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.signInWithApple(
          oauthIntendedRole: oauthIntendedRole,
        );
        await localDataSource.cacheUser(user);
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on ForbiddenException catch (e) {
        return Left(ForbiddenFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
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
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ForbiddenFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No Internet Connection'));
    }
    try {
      await remoteDataSource.deleteAccount();
      await localDataSource.clearCache();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ForbiddenFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
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
      } on EmailVerificationRequiredException catch (e) {
        return Left(EmailVerificationPendingFailure(e.email));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on ForbiddenException catch (e) {
        return Left(ForbiddenFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, void>> resendVerificationEmail(String email) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resendVerificationEmail(email);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPasswordForEmail(String email) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resetPasswordForEmail(email);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword(String newPassword) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updatePassword(newPassword);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCachedUser();
      return Right(user);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> cacheUserProfile(User user) async {
    try {
      await localDataSource.cacheUser(
        UserModel(
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          avatarUrl: user.avatarUrl,
          city: user.city,
        ),
      );
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> updateHomeCity(String city) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No Internet Connection'));
    }
    try {
      final user = await remoteDataSource.updateProfileCity(city);
      await localDataSource.cacheUser(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ForbiddenFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
}
