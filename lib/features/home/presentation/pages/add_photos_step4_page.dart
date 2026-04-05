import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/business_media_limits.dart';
import '../../../../core/constants/legal_document_storage.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../../../../core/services/image_picker_service.dart';
import 'package:habra_mobile_app/core/services/storage_service.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import 'listing_status_page.dart';

// API_ASSUMPTIONS (registration): `businesses` row accepts `image_urls` (e.g. text[] or jsonb)
// for extra photos; `business_legal_documents` accepts `document_type` `business_license`
// and optional `ein_proof`. Adjust payload if your schema differs.

/// Registration step 4: Cover, logo, optional gallery, Business License (required), EIN Proof (optional).
class AddPhotosStep4Page extends StatefulWidget {
  const AddPhotosStep4Page({super.key, this.step3Data = const {}});

  final Map<String, String> step3Data;

  @override
  State<AddPhotosStep4Page> createState() => _AddPhotosStep4PageState();
}

class _AddPhotosStep4PageState extends State<AddPhotosStep4Page> {
  File? _coverFile;
  File? _logoFile;
  final List<File> _galleryFiles = [];
  File? _licenseFile;
  File? _einFile;
  bool _isSubmitting = false;

  static const int _maxLegalBytes = 10 * 1024 * 1024;

  static String _fileBasename(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final i = normalized.lastIndexOf('/');
    return i >= 0 ? normalized.substring(i + 1) : normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 24,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Add Photos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Showcase your business with photos, then upload your business license (required) '
                'and EIN proof (optional) so we can verify your listing.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _buildPhotoSection(
                title: 'Cover Photo',
                hint: 'Tap to upload cover photo',
                file: _coverFile,
                onTap: () async {
                  final f = await di.sl<ImagePickerService>().pickImage(context);
                  if (f != null && mounted) setState(() => _coverFile = f);
                },
                onRemove: () => setState(() => _coverFile = null),
              ),
              const SizedBox(height: 24),
              _buildPhotoSection(
                title: 'Logo',
                hint: 'Tap to upload logo',
                file: _logoFile,
                onTap: () async {
                  final f = await di.sl<ImagePickerService>().pickImage(context);
                  if (f != null && mounted) setState(() => _logoFile = f);
                },
                onRemove: () => setState(() => _logoFile = null),
              ),
              const SizedBox(height: 24),
              Text(
                'More photos (optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add up to ${BusinessMediaLimits.maxGalleryImages} gallery images. Max 5 MB each.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._galleryFiles.map((file) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppResources.radiusM),
                          child: Image.file(
                            file,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.backgroundWhite,
                              padding: const EdgeInsets.all(4),
                              minimumSize: const Size(28, 28),
                            ),
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setState(() => _galleryFiles.remove(file)),
                          ),
                        ),
                      ],
                    );
                  }),
                  Material(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                    child: InkWell(
                      onTap: () async {
                        if (_galleryFiles.length >=
                            BusinessMediaLimits.maxGalleryImages) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'You can add up to ${BusinessMediaLimits.maxGalleryImages} gallery photos.',
                              ),
                            ),
                          );
                          return;
                        }
                        final f =
                            await di.sl<ImagePickerService>().pickImage(context);
                        if (f != null && mounted) {
                          setState(() => _galleryFiles.add(f));
                        }
                      },
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                      child: Container(
                        width: 88,
                        height: 88,
                        alignment: Alignment.center,
                        child: Icon(Icons.add_photo_alternate,
                            color: AppColors.brandPrimary, size: 32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Legal documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Required for registration. Files are reviewed by our team.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 4,
                runSpacing: 4,
                children: [
                  Text(
                    'Business License ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '(Required)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Current business license, resale certificate, or similar. PDF or image, max 10 MB.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _buildLegalFileTile(
                file: _licenseFile,
                emptyLabel: 'Tap to upload Business License',
                onTap: () => _pickLegalFile(isLicense: true),
                onRemove: () => setState(() => _licenseFile = null),
              ),
              const SizedBox(height: 24),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 4,
                runSpacing: 4,
                children: [
                  Text(
                    'EIN Proof ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '(Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'IRS EIN assignment letter, Form SS-4 confirmation, or equivalent. PDF or image, max 10 MB.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _buildLegalFileTile(
                file: _einFile,
                emptyLabel: 'Tap to upload EIN Proof',
                onTap: () => _pickLegalFile(isLicense: false),
                onRemove: () => setState(() => _einFile = null),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppResources.spacingM),
          child: AppButton(
            text: 'Complete Registration',
            onPressed: (_coverFile != null &&
                    _logoFile != null &&
                    _licenseFile != null &&
                    !_isSubmitting)
                ? _onComplete
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection({
    required String title,
    required String hint,
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
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(Required)',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'The main image users will see on your listing. Max 5 MB per file.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppResources.radiusL),
              border: Border.all(color: AppColors.backgroundGrey),
            ),
            child: file != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppResources.radiusL),
                        child: Image.file(file, fit: BoxFit.cover),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: FutureBuilder<int>(
                          future: file.length(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox.shrink();
                            final bytes = snapshot.data!;
                            final overLimit = bytes > FileUtils.maxImageBytes;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${FileUtils.formatFileSize(bytes)} / 5 MB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: overLimit ? AppColors.error : Colors.white,
                                  fontWeight: overLimit ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: onRemove,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: AppColors.brandSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hint,
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

  Future<void> _pickLegalFile({required bool isLicense}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null || !mounted) return;
    final file = File(result.files.single.path!);
    final size = await file.length();
    if (!mounted) return;
    if (size > _maxLegalBytes) {
      ErrorDisplayHelper.show(
        context,
        message: 'File must be under 10 MB.',
        title: 'File too large',
      );
      return;
    }
    setState(() {
      if (isLicense) {
        _licenseFile = file;
      } else {
        _einFile = file;
      }
    });
  }

  Widget _buildLegalFileTile({
    required File? file,
    required String emptyLabel,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Material(
      color: AppColors.backgroundLight,
      borderRadius: BorderRadius.circular(AppResources.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppResources.radiusM),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppResources.radiusM),
            border: Border.all(
              color: file != null ? AppColors.brandPrimary : AppColors.backgroundGrey,
              width: file != null ? 2 : 1,
            ),
          ),
          child: file == null
              ? Row(
                  children: [
                    Icon(Icons.upload_file, color: AppColors.textTertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        emptyLabel,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: AppColors.brandPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fileBasename(file.path),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _onComplete() async {
    final ctx = context;
    for (final f in [_coverFile, _logoFile, ..._galleryFiles]) {
      if (f != null) {
        final size = await f.length();
        if (!ctx.mounted) return;
        if (size > FileUtils.maxImageBytes) {
          ErrorDisplayHelper.show(
            ctx,
            message: 'Image is ${FileUtils.formatFileSize(size)}. Max 5 MB per file.',
            title: 'File too large',
          );
          return;
        }
      }
    }
    if (_licenseFile == null) return;
    final licSize = await _licenseFile!.length();
    if (!ctx.mounted) return;
    if (licSize > _maxLegalBytes) {
      ErrorDisplayHelper.show(
        ctx,
        message: 'Business license must be under 10 MB.',
        title: 'File too large',
      );
      return;
    }
    if (_einFile != null) {
      final einSize = await _einFile!.length();
      if (!ctx.mounted) return;
      if (einSize > _maxLegalBytes) {
        ErrorDisplayHelper.show(
          ctx,
          message: 'EIN document must be under 10 MB.',
          title: 'File too large',
        );
        return;
      }
    }
    if (!ctx.mounted) return;

    setState(() => _isSubmitting = true);
    LoaderHelper.show(
      ctx,
      backgroundColor: Colors.white.withValues(alpha: 0.82),
    );

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Not authenticated');
      }

      String? logoUrl;
      String? backgroundUrl;
      final pathPrefix = '$userId/new/${DateTime.now().millisecondsSinceEpoch}';

      if (_logoFile != null) {
        logoUrl = await di.sl<StorageService>().uploadImage(
          SupabaseBuckets.businesses,
          '$pathPrefix/logo',
          _logoFile!,
        );
        if (!ctx.mounted) return;
      }
      if (_coverFile != null) {
        backgroundUrl = await di.sl<StorageService>().uploadImage(
          SupabaseBuckets.businesses,
          '$pathPrefix/background',
          _coverFile!,
        );
        if (!ctx.mounted) return;
      }

      List<String>? galleryUrls;
      if (_galleryFiles.isNotEmpty) {
        galleryUrls = await di.sl<StorageService>().uploadImages(
          SupabaseBuckets.businesses,
          '$pathPrefix/gallery',
          _galleryFiles,
        );
        if (!ctx.mounted) return;
      }

      final street = widget.step3Data['address_street'] ?? '';
      final suite = widget.step3Data['address_suite'];
      final addressStreet = suite != null && suite.isNotEmpty
          ? '$street${street.isNotEmpty ? ', ' : ''}$suite'
          : street;

      final data = <String, dynamic>{
        'name': widget.step3Data['name'] ?? 'New Business',
        'phone': widget.step3Data['phone']?.isNotEmpty == true
            ? widget.step3Data['phone']
            : null,
        'email': widget.step3Data['email']?.isNotEmpty == true
            ? widget.step3Data['email']
            : null,
        'website': widget.step3Data['website']?.isNotEmpty == true
            ? widget.step3Data['website']
            : null,
        'address_street': addressStreet.isNotEmpty ? addressStreet : null,
        'address_city': widget.step3Data['address_city'] ?? 'Unknown',
        'address_state': widget.step3Data['address_state']?.isNotEmpty == true
            ? widget.step3Data['address_state']
            : null,
        'address_zip': widget.step3Data['address_zip']?.isNotEmpty == true
            ? widget.step3Data['address_zip']
            : null,
        'opening_time': widget.step3Data['opening_time'],
        'closing_time': widget.step3Data['closing_time'],
        'logo_url': logoUrl,
        'background_url': backgroundUrl,
        if (galleryUrls != null && galleryUrls.isNotEmpty) 'image_urls': galleryUrls,
      };
      data.removeWhere((_, v) => v == null);

      var businessId = await di.sl<DashboardCubit>().createBusiness(userId, data);
      if (businessId == null && galleryUrls != null && data.remove('image_urls') != null) {
        businessId = await di.sl<DashboardCubit>().createBusiness(userId, data);
      }
      if (!ctx.mounted) return;
      if (businessId == null) {
        throw Exception('Failed to create business');
      }
      final createdBusinessId = businessId;

      final categoryId = widget.step3Data['category_id'];
      if (categoryId != null && categoryId.trim().isNotEmpty) {
        await di.sl<DashboardRepository>().replaceBusinessCategoryLinks(
          createdBusinessId,
          [categoryId.trim()],
        );
      }

      final cubit = di.sl<DashboardCubit>();
      final storage = di.sl<StorageService>();
      try {
        final licenseUpload = await storage.uploadLegalDocumentFile(
          _licenseFile!,
          pathPrefix:
              '$createdBusinessId/reg_${LegalDocumentStorage.typeBusinessLicense}',
        );
        await cubit.uploadLegalDocument(
          createdBusinessId,
          LegalDocumentStorage.typeBusinessLicense,
          licenseUpload,
          fileName: _fileBasename(_licenseFile!.path),
        );
        if (_einFile != null) {
          final einUpload = await storage.uploadLegalDocumentFile(
            _einFile!,
            pathPrefix:
                '$createdBusinessId/reg_${LegalDocumentStorage.typeEinProof}',
          );
          await cubit.uploadLegalDocument(
            createdBusinessId,
            LegalDocumentStorage.typeEinProof,
            einUpload,
            fileName: _fileBasename(_einFile!.path),
          );
        }
      } catch (docErr) {
        if (ctx.mounted) {
          ErrorDisplayHelper.show(
            ctx,
            error: docErr,
            title: 'Business created',
            message:
                'Your business was created, but we could not upload legal documents. '
                'Upload them from the dashboard when prompted.',
          );
        }
      }

      if (!ctx.mounted) return;
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      setState(() => _isSubmitting = false);
      if (!ctx.mounted) return;
      final cityRaw =
          widget.step3Data['address_city']?.toString().trim() ?? '';
      final cityForStatus = cityRaw.isNotEmpty &&
              cityRaw.toLowerCase() != 'unknown'
          ? cityRaw
          : null;
      final streetRaw =
          widget.step3Data['address_street']?.toString().trim() ?? '';
      final locationLine = cityForStatus == null
          ? null
          : (streetRaw.isNotEmpty ? '$streetRaw, $cityRaw' : cityRaw);

      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ListingStatusPage(
            isVerified: false,
            businessId: createdBusinessId,
            businessName: widget.step3Data['name']?.toString() ?? 'Your business',
            cityName: cityForStatus,
            imageUrl: logoUrl ?? backgroundUrl ?? '',
            locationText: locationLine,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (ctx.mounted) {
        await LoaderHelper.hide(ctx);
        if (ctx.mounted) {
          setState(() => _isSubmitting = false);
          ErrorDisplayHelper.show(ctx, error: e, title: 'Registration failed');
        }
      }
    }
  }
}
