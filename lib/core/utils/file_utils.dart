import 'dart:io';

/// Utilities for file size formatting and validation.
class FileUtils {
  FileUtils._();

  /// Max file size for image uploads (5MB).
  static const int maxImageBytes = 5 * 1024 * 1024;

  /// Format bytes as human-readable string (e.g. "2.3 MB", "512 KB").
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if file is within the max image size limit.
  static Future<bool> isWithinImageLimit(File file) async {
    final length = await file.length();
    return length <= maxImageBytes;
  }
}
