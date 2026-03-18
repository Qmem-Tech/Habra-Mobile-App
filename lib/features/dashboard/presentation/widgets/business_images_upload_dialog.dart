import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import '../../../../core/widgets/error_display_helper.dart';
import '../bloc/dashboard_cubit.dart';
import '../../../../injection/injection_container.dart' as di;

/// Mandatory dialog for business owners to upload logo and background image.
/// Cannot be dismissed until both are uploaded.
class BusinessImagesUploadDialog extends StatefulWidget {
  const BusinessImagesUploadDialog({
    super.key,
    required this.businessId,
    required this.businessName,
    this.initialLogoUrl,
    this.initialBackgroundUrl,
  });

  final String businessId;
  final String businessName;
  final String? initialLogoUrl;
  final String? initialBackgroundUrl;

  @override
  State<BusinessImagesUploadDialog> createState() =>
      _BusinessImagesUploadDialogState();
}

class _BusinessImagesUploadDialogState extends State<BusinessImagesUploadDialog> {
  File? _logoFile;
  File? _backgroundFile;
  List<File> _galleryFiles = [];

  String? get _logoUrl => widget.initialLogoUrl;
  String? get _backgroundUrl => widget.initialBackgroundUrl;

  bool get _hasLogo =>
      _logoFile != null ||
      (_logoUrl != null && _logoUrl!.isNotEmpty);
  bool get _hasBackground =>
      _backgroundFile != null ||
      (_backgroundUrl != null && _backgroundUrl!.isNotEmpty);
  bool get _canSave => _hasLogo && _hasBackground;

  Future<void> _pickLogo() async {
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file != null && mounted) {
      setState(() => _logoFile = file);
    }
  }

  Future<void> _pickBackground() async {
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file != null && mounted) {
      setState(() => _backgroundFile = file);
    }
  }

  Future<void> _pickGalleryImage() async {
    final file = await di.sl<ImagePickerService>().pickImage(context);
    if (file != null && mounted) {
      setState(() => _galleryFiles = [..._galleryFiles, file]);
    }
  }

  void _removeGalleryImage(int index) {
    setState(() => _galleryFiles.removeAt(index));
  }

  Future<void> _save() async {
    if (!_canSave) return;

    final ctx = context;
    final cubit = ctx.read<DashboardCubit>();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    LoaderHelper.show(ctx, message: 'Uploading...');

    try {
      String? logoUrl = _logoUrl;
      String? backgroundUrl = _backgroundUrl;

      if (_logoFile != null) {
        logoUrl = await di.sl<StorageService>().uploadImage(
          SupabaseBuckets.businesses,
          '${widget.businessId}/logo',
          _logoFile!,
        );
      }
      if (_backgroundFile != null) {
        backgroundUrl = await di.sl<StorageService>().uploadImage(
          SupabaseBuckets.businesses,
          '${widget.businessId}/background',
          _backgroundFile!,
        );
      }

      final data = <String, dynamic>{
        'logo_url': logoUrl ?? _logoUrl,
        'background_url': backgroundUrl ?? _backgroundUrl,
      };

      if (_galleryFiles.isNotEmpty) {
        final urls = await di.sl<StorageService>().uploadImages(
          SupabaseBuckets.businesses,
          '${widget.businessId}/gallery',
          _galleryFiles,
        );
        data['image_urls'] = urls;
      }

      await cubit.updateBusiness(widget.businessId, data);

      if (!ctx.mounted) return;
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop(true);
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
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppResources.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.image, color: AppColors.brandPrimary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add Business Images',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Logo and background image are required for ${widget.businessName}.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                _buildUploadSection(
                  label: 'Logo',
                  required: true,
                  hasImage: _hasLogo,
                  imageFile: _logoFile,
                  imageUrl: _logoUrl,
                  onTap: _pickLogo,
                ),
                const SizedBox(height: 20),
                _buildUploadSection(
                  label: 'Background / Cover',
                  required: true,
                  hasImage: _hasBackground,
                  imageFile: _backgroundFile,
                  imageUrl: _backgroundUrl,
                  onTap: _pickBackground,
                ),
                const SizedBox(height: 20),
                _buildOptionalGallerySection(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Save',
                    onPressed: _canSave ? _save : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection({
    required String label,
    required bool required,
    required bool hasImage,
    File? imageFile,
    String? imageUrl,
    required VoidCallback onTap,
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
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppResources.radiusM),
              border: Border.all(
                color: hasImage ? AppColors.brandPrimary : AppColors.backgroundGrey,
                width: hasImage ? 2 : 1,
              ),
            ),
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                        child: imageFile != null
                            ? Image.file(imageFile, fit: BoxFit.cover)
                            : Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholder(),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          onPressed: onTap,
                        ),
                      ),
                    ],
                  )
                : _buildPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 40, color: AppColors.textTertiary),
        const SizedBox(height: 8),
        Text(
          'Tap to upload',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildOptionalGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Gallery Images',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              ' (Optional)',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickGalleryImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppResources.radiusM),
                    border: Border.all(color: AppColors.backgroundGrey),
                  ),
                  child: Icon(Icons.add, color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(_galleryFiles.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppResources.radiusM),
                        child: Image.file(
                          _galleryFiles[i],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeGalleryImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
