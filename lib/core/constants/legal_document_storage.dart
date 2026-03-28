/// **Canonical contract** — legal document Storage + DB rows (align with admin web / SQL).
///
/// - **Bucket:** Always [`bucketId`]. Every `business_legal_documents` row should set
///   `storage_bucket` to this value (do not rely on implicit defaults in production).
/// - **Path:** `storage_path` is the exact object key passed to Storage `upload()` — no
///   leading `/`. Prefer safe names (`uuid.ext` or `timestamp.ext`); keep human names in
///   `file_name` only.
/// - **Table:** `business_legal_documents` columns: `business_id`, `document_type`,
///   `storage_bucket`, `storage_path`, `file_url` (public URL for convenience),
///   `file_name`, `mime_type`, `file_size_bytes`, `status`, …
///
/// Same ideas as `src/lib/legalDocumentBuckets.ts` on the web admin — keep values in sync.
abstract final class LegalDocumentStorage {
  LegalDocumentStorage._();

  /// Supabase Storage bucket id (matches `storage.buckets` and RLS policies).
  static const String bucketId = 'legal_documents';

  /// Stable `document_type` codes for inserts.
  static const String typeBusinessLicense = 'business_license';
  static const String typeEinProof = 'ein_proof';
}
