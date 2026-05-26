import '../constants/legal_document_storage.dart';

/// Result of uploading one file to the legal documents bucket (for DB insert).
class LegalDocumentUploadResult {
  const LegalDocumentUploadResult({
    required this.publicUrl,
    required this.storagePath,
    this.storageBucket = LegalDocumentStorage.bucketId,
    required this.mimeType,
    required this.fileSizeBytes,
  });

  final String publicUrl;
  final String storagePath;
  final String storageBucket;
  final String mimeType;
  final int fileSizeBytes;
}
