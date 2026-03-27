import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for uploading files to Supabase Storage.
class StorageService {
  StorageService();

  SupabaseClient get _client => Supabase.instance.client;

  /// Upload an image to a bucket. Returns the public URL.
  /// [bucket] - e.g. SupabaseBuckets.events, SupabaseBuckets.deals, SupabaseBuckets.reviews
  /// [pathPrefix] - e.g. 'eventId' or 'userId/businessId'
  Future<String> uploadImage(
    String bucket,
    String pathPrefix,
    File file, {
    int maxBytes = 5 * 1024 * 1024,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'].contains(ext)) {
      throw Exception(
        'Please upload JPG, PNG, WebP, GIF, or HEIC (max 5MB)',
      );
    }
    if (await file.length() > maxBytes) {
      throw Exception('Image must be under ${maxBytes ~/ (1024 * 1024)}MB');
    }
    final path = '$pathPrefix/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final contentType = _imageContentType(ext);
    await _client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Upload a document (PDF, JPG, PNG) to a bucket. Returns the public URL.
  /// Used for legal documents etc.
  Future<String> uploadDocument(
    String bucket,
    String pathPrefix,
    File file, {
    int maxBytes = 10 * 1024 * 1024,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'pdf', 'webp'].contains(ext)) {
      throw Exception('Please upload JPG, PNG, PDF, or WebP (max 10MB)');
    }
    if (await file.length() > maxBytes) {
      throw Exception('File must be under ${maxBytes ~/ (1024 * 1024)}MB');
    }
    final path = '$pathPrefix/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Upload multiple images. Returns list of public URLs.
  Future<List<String>> uploadImages(
    String bucket,
    String pathPrefix,
    List<File> files,
  ) async {
    final urls = <String>[];
    final ts = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < files.length; i++) {
      final url = await uploadImage(bucket, '$pathPrefix/${ts}_$i', files[i]);
      urls.add(url);
    }
    return urls;
  }

  static String _imageContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }
}
