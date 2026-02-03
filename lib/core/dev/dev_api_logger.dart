import 'package:flutter/foundation.dart';

/// Single API call log (request + response).
/// Used only in debug mode for dev overlay.
class ApiLogEntry {
  ApiLogEntry({
    required this.id,
    required this.method,
    required this.path,
    required this.requestTime,
    this.requestHeaders,
    this.requestData,
    this.responseStatus,
    this.responseTime,
    this.responseHeaders,
    this.responseData,
    this.errorMessage,
  });

  final String id;
  final String method;
  final String path;
  final DateTime requestTime;
  final Map<String, dynamic>? requestHeaders;
  final dynamic requestData;
  final int? responseStatus;
  final DateTime? responseTime;
  final Map<String, dynamic>? responseHeaders;
  final dynamic responseData;
  final String? errorMessage;

  bool get isError => errorMessage != null;

  /// Full text for copy: request + response.
  String get copyableText {
    final buffer = StringBuffer();
    buffer.writeln('$method $path');
    buffer.writeln('Request: ${requestTime.toIso8601String()}');
    if (requestHeaders != null && requestHeaders!.isNotEmpty) {
      buffer.writeln('Request headers: $requestHeaders');
    }
    if (requestData != null) {
      buffer.writeln('Request body: $requestData');
    }
    buffer.writeln('---');
    if (errorMessage != null) {
      buffer.writeln('Error: $errorMessage');
    } else {
      buffer.writeln('Response: ${responseTime?.toIso8601String()}');
      buffer.writeln('Status: $responseStatus');
      if (responseHeaders != null && responseHeaders!.isNotEmpty) {
        buffer.writeln('Response headers: $responseHeaders');
      }
      if (responseData != null) {
        buffer.writeln('Response body: $responseData');
      }
    }
    return buffer.toString();
  }
}

/// Global dev-only logger that stores API request/response for the overlay.
/// Only active when [kDebugMode] is true.
class DevApiLogger {
  DevApiLogger._();

  static final DevApiLogger instance = DevApiLogger._();

  final List<ApiLogEntry> _entries = [];
  final ValueNotifier<int> _updateNotifier = ValueNotifier<int>(0);

  /// Only capture API calls after user has opened the dev panel (e.g. sign in, sign up).
  bool _recordingEnabled = false;

  List<ApiLogEntry> get entries => List.unmodifiable(_entries);
  ValueNotifier<int> get updateNotifier => _updateNotifier;
  bool get recordingEnabled => _recordingEnabled;

  void enableRecording() {
    if (!kDebugMode) return;
    _recordingEnabled = true;
  }

  void addEntry(ApiLogEntry entry) {
    if (!kDebugMode || !_recordingEnabled) return;
    _entries.insert(0, entry);
    // Keep last 50 entries
    while (_entries.length > 50) {
      _entries.removeLast();
    }
    _updateNotifier.value++;
  }

  void clear() {
    _entries.clear();
    _updateNotifier.value++;
  }
}
