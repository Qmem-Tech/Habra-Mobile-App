import 'package:equatable/equatable.dart';

/// One row from `business_legal_documents` for owner-facing views.
class BusinessLegalDocument extends Equatable {
  final String id;
  final String businessId;
  final String documentType;
  final String fileUrl;
  final String? fileName;
  final String status;
  final DateTime? uploadedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const BusinessLegalDocument({
    required this.id,
    required this.businessId,
    required this.documentType,
    required this.fileUrl,
    this.fileName,
    required this.status,
    this.uploadedAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        documentType,
        fileUrl,
        fileName,
        status,
        uploadedAt,
        reviewedAt,
        rejectionReason,
      ];
}
