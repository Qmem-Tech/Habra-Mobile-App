import 'package:dio/dio.dart';
import '../../storage/local_storage.dart';
import '../../constants/storage_keys.dart';

class AuthInterceptor extends Interceptor {
  final LocalStorage localStorage;

  AuthInterceptor(this.localStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await localStorage.getString(StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}
