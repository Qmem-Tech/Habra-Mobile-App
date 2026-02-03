import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/dev_api_interceptor.dart';
import '../storage/local_storage.dart';

class ApiClient {
  late Dio _dio;

  ApiClient(LocalStorage localStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl + ApiConstants.apiVersion,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final interceptors = [
      LoggingInterceptor(),
      AuthInterceptor(localStorage),
    ];
    if (kDebugMode) {
      interceptors.add(DevApiInterceptor());
    }
    _dio.interceptors.addAll(interceptors);
  }

  Dio get dio => _dio;
}
