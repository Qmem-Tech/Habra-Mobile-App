import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../dev/dev_api_logger.dart';

/// Interceptor that captures API request/response for the dev overlay.
/// Only runs when [kDebugMode] is true.
class DevApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }
    _captureResponse(
      options: response.requestOptions,
      statusCode: response.statusCode,
      responseData: response.data,
      responseHeaders: response.headers.map,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(err);
      return;
    }
    _captureResponse(
      options: err.requestOptions,
      statusCode: err.response?.statusCode,
      responseData: err.response?.data,
      responseHeaders: err.response?.headers.map,
      errorMessage: err.message ?? err.toString(),
    );
    handler.next(err);
  }

  void _captureResponse({
    required RequestOptions options,
    int? statusCode,
    dynamic responseData,
    Map<String, List<String>>? responseHeaders,
    String? errorMessage,
  }) {
    final id = '${options.uri}_${DateTime.now().millisecondsSinceEpoch}';
    final entry = ApiLogEntry(
      id: id,
      method: options.method,
      path: options.uri.toString(),
      requestTime: DateTime.now(),
      requestHeaders: options.headers.isEmpty ? null : Map<String, dynamic>.from(options.headers),
      requestData: _safeData(options.data),
      responseStatus: statusCode,
      responseTime: DateTime.now(),
      responseHeaders: responseHeaders != null
          ? responseHeaders.map((k, v) => MapEntry(k, v.join(', ')))
          : null,
      responseData: _safeData(responseData),
      errorMessage: errorMessage,
    );
    DevApiLogger.instance.addEntry(entry);
  }

  static dynamic _safeData(dynamic data) {
    if (data == null) return null;
    if (data is Map || data is List) return data;
    return data.toString();
  }
}
