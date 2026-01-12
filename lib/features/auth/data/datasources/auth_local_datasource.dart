import '../models/user_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/constants/storage_keys.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalStorage localStorage;

  AuthLocalDataSourceImpl(this.localStorage);

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await localStorage.setString(StorageKeys.userData, userJson);
      await localStorage.setBool(StorageKeys.isLoggedIn, true);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userJson = await localStorage.getString(StorageKeys.userData);
      if (userJson != null) {
        return UserModel.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await localStorage.remove(StorageKeys.userData);
      await localStorage.setBool(StorageKeys.isLoggedIn, false);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
