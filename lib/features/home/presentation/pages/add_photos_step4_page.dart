import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loader_helper.dart';
import 'listing_status_page.dart';

/// Add Photos step 4: Cover Photo, Logo (required), Complete Registration.
class AddPhotosStep4Page extends StatefulWidget {
  const AddPhotosStep4Page({super.key});

  @override
  State<AddPhotosStep4Page> createState() => _AddPhotosStep4PageState();
}

class _AddPhotosStep4PageState extends State<AddPhotosStep4Page> {
  bool _coverPicked = false;
  bool _logoPicked = false;
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
                isPicked: _coverPicked,
                onTap: () => setState(() => _coverPicked = true),
              ),
              const SizedBox(height: 24),
              _buildPhotoSection(
                title: 'Logo',
                hint: 'Tap to upload logo',
                isPicked: _logoPicked,
                onTap: () => setState(() => _logoPicked = true),
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
            onPressed: (_coverPicked && _logoPicked && !_isSubmitting)
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
    required bool isPicked,
    required VoidCallback onTap,
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
          'The main image users will see on your listing.',
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
            child: isPicked
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 48, color: AppColors.success),
                        const SizedBox(height: 8),
                        Text(
                          'Photo added',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
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
    setState(() => _isSubmitting = true);
    LoaderHelper.show(context, message: 'Completing registration...');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _afterRegistrationComplete();
  }

  void _afterRegistrationComplete() {
    if (!context.mounted) return;
    LoaderHelper.hide(context);
    setState(() => _isSubmitting = false);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ListingStatusPage(isVerified: true),
      ),
    );
  }
}
