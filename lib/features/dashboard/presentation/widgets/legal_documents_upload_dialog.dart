import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/legal_document_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/dashboard_cubit.dart';

/// Upload business license (required) and EIN proof (optional).
/// **API:** Inserts into `business_legal_documents` with `document_type`
/// `business_license` and optional `ein_proof`.
class LegalDocumentsUploadDialog extends StatefulWidget {
  const LegalDocumentsUploadDialog({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<LegalDocumentsUploadDialog> createState() =>
      _LegalDocumentsUploadDialogState();
}

class _LegalDocumentsUploadDialogState extends State<LegalDocumentsUploadDialog> {
  File? _licenseFile;
  File? _einFile;

  bool get _canSave => _licenseFile != null;

  Future<void> _pickDocument(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null && mounted) {
      final file = File(result.files.single.path!);
      final size = await file.length();
      if (size > 10 * 1024 * 1024) {
        if (!mounted) {
          return;
        }
        ErrorDisplayHelper.show(
          context,
          message: 'File must be under 10MB.',
          title: 'File too large',
        );
        return;
      }
      setState(() {
        if (index == 1) {
          _licenseFile = file;
        } else {
          _einFile = file;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;

    final ctx = context;
    final cubit = ctx.read<DashboardCubit>();
    LoaderHelper.show(ctx, message: 'Uploading...');

    try {
      final storage = di.sl<StorageService>();
      final bid = widget.businessId;

      final licenseUpload = await storage.uploadLegalDocumentFile(
        _licenseFile!,
        pathPrefix: '$bid/${LegalDocumentStorage.typeBusinessLicense}',
      );
      await cubit.uploadLegalDocument(
        widget.businessId,
        LegalDocumentStorage.typeBusinessLicense,
        licenseUpload,
        fileName: _licenseFile!.path.split('/').last,
      );

      if (_einFile != null) {
        final einUpload = await storage.uploadLegalDocumentFile(
          _einFile!,
          pathPrefix: '$bid/${LegalDocumentStorage.typeEinProof}',
        );
        await cubit.uploadLegalDocument(
          widget.businessId,
          LegalDocumentStorage.typeEinProof,
          einUpload,
          fileName: _einFile!.path.split('/').last,
        );
      }

      if (!ctx.mounted) return;
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      Navigator.of(ctx, rootNavigator: true).pop(true);
    } catch (e) {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
        if (ctx.mounted) {
          ErrorDisplayHelper.show(ctx, error: e, title: 'Upload failed');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Padding(
        padding: const EdgeInsets.all(AppResources.spacingL),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description, color: AppColors.brandPrimary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Legal documents',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload your business license for ${widget.businessName}. '
                          'EIN proof is optional. A super admin will review and approve.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDocumentSection(
                label: 'Business license',
                required: true,
                file: _licenseFile,
                onTap: () => _pickDocument(1),
                onRemove: () => setState(() => _licenseFile = null),
              ),
              const SizedBox(height: 16),
              _buildDocumentSection(
                label: 'EIN proof (optional)',
                required: false,
                file: _einFile,
                onTap: () => _pickDocument(2),
                onRemove: () => setState(() => _einFile = null),
              ),
              const SizedBox(height: 8),
              Text(
                'Accepted: PDF, JPG, PNG (max 10MB each)',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Submit for Review',
                  onPressed: _canSave ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentSection({
    required String label,
    required bool required,
    required File? file,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (required)
              Text(
                ' (Required)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              border: Border.all(
                color: file != null ? AppColors.brandPrimary : AppColors.backgroundGrey,
                width: file != null ? 2 : 1,
              ),
            ),
            child: file != null
                ? Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: AppColors.brandPrimary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.path.split('/').last,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            FutureBuilder<int>(
                              future: file.length(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox.shrink();
                                return Text(
                                  FileUtils.formatFileSize(snapshot.data!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: AppColors.textTertiary),
                      const SizedBox(width: 12),
                      Text(
                        'Tap to select file (PDF, JPG, PNG)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
