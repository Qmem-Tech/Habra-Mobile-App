import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import 'listing_status_page.dart';

/// Add Photos step 4: Cover Photo, Logo (required), Complete Registration.
class AddPhotosStep4Page extends StatefulWidget {
  const AddPhotosStep4Page({super.key, this.step3Data = const {}});

  final Map<String, String> step3Data;

  @override
  State<AddPhotosStep4Page> createState() => _AddPhotosStep4PageState();
}

class _AddPhotosStep4PageState extends State<AddPhotosStep4Page> {
  File? _coverFile;
  File? _logoFile;
  bool _isSubmitting = false;

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
                'Showcase your business to the community. Great photos attract more customers.',
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
            onPressed: (_coverFile != null && _logoFile != null && !_isSubmitting)
                ? _onComplete
                : null,
            isLoading: _isSubmitting,
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

  Future<void> _onComplete() async {
    final ctx = context;
    for (final f in [_coverFile, _logoFile]) {
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
    if (!ctx.mounted) return;

    setState(() => _isSubmitting = true);
    LoaderHelper.show(ctx, message: 'Completing registration...');

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

      final street = widget.step3Data['address_street'] ?? '';
      final suite = widget.step3Data['address_suite'];
      final addressStreet = suite != null && suite.isNotEmpty
          ? '$street${street.isNotEmpty ? ', ' : ''}$suite'
          : street;

      final data = <String, dynamic>{
        'name': widget.step3Data['name'] ?? 'New Business',
        'description': widget.step3Data['category'],
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
      };
      data.removeWhere((_, v) => v == null);

      final businessId = await di.sl<DashboardCubit>().createBusiness(userId, data);
      if (!ctx.mounted) return;
      if (businessId == null) {
        throw Exception('Failed to create business');
      }
      await LoaderHelper.hide(ctx);
      if (!ctx.mounted) return;
      setState(() => _isSubmitting = false);
      if (!ctx.mounted) return;
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ListingStatusPage(
            isVerified: false,
            businessId: businessId,
            businessName: widget.step3Data['name'] ?? 'Your business',
            imageUrl: logoUrl ?? backgroundUrl ?? '',
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
