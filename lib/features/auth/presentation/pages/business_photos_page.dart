import 'package:flutter/material.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import 'business_live_page.dart';

class BusinessPhotosPage extends StatefulWidget {
  const BusinessPhotosPage({super.key});

  @override
  State<BusinessPhotosPage> createState() => _BusinessPhotosPageState();
}

class _BusinessPhotosPageState extends State<BusinessPhotosPage> {
  String? _coverPhotoPath;

  void _onUploadCoverPhoto() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker coming soon')),
    );
    // For now, simulate upload
    setState(() {
      _coverPhotoPath = 'uploaded';
    });
  }

  void _onCompleteRegistration() {
    if (_coverPhotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a cover photo')),
      );
      return;
    }

    // TODO: Complete registration with backend
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const BusinessLivePage(),
      ),
    );
  }

  void _onSkip() {
    // TODO: Complete registration without photo
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const BusinessLivePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.only(right: AppResources.spacingL),
            child: Row(
              children: List.generate(5, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: index < 4 ? 24 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: index < 4 ? AppColors.brandPrimary : AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppResources.spacingL,
            vertical: AppResources.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppResources.spacingXL),

              // Title
              Text(
                'Add Photos',
                style: AppFonts.largeTitle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppResources.spacingM),

              // Description
              Text(
                'Showcase your business to the community. Great photos attract more customers.',
                style: AppFonts.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppResources.spacingXXL),

              // Cover Photo section
              Text(
                'Cover Photo',
                style: AppFonts.mediumTitle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppResources.spacingXS),
              RichText(
                text: TextSpan(
                  style: AppFonts.bodySmall(color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'The main image users will see on your listing. '),
                    TextSpan(
                      text: '(Required)',
                      style: AppFonts.bodySmall(color: AppColors.error),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppResources.spacingM),

              // Upload area
              InkWell(
                onTap: _onUploadCoverPhoto,
                borderRadius: BorderRadius.circular(AppResources.radiusL),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppResources.radiusL),
                    border: Border.all(
                      color: AppColors.backgroundGrey,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _coverPhotoPath != null
                      ? Stack(
                          children: [
                            // Placeholder for uploaded image
                            Center(
                              child: Icon(
                                Icons.check_circle,
                                size: 60,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                            Positioned(
                              top: AppResources.spacingM,
                              right: AppResources.spacingM,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _coverPhotoPath = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.brandSecondary.withValues(alpha:0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add,
                                size: 32,
                                color: AppColors.brandSecondary,
                              ),
                            ),
                            const SizedBox(height: AppResources.spacingM),
                            Text(
                              'Tap to upload cover photo',
                              style: AppFonts.body(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppResources.spacingXXL),

              // Complete Registration button
              SizedBox(
                width: double.infinity,
                height: AppResources.buttonHeightM,
                child: ElevatedButton(
                  onPressed: _onCompleteRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: Text(
                    'Complete Registration',
                    style: AppFonts.button(color: AppColors.textOnPrimary),
                  ),
                ),
              ),
              const SizedBox(height: AppResources.spacingM),

              // Skip for now link
              Center(
                child: TextButton(
                  onPressed: _onSkip,
                  child: Text(
                    'Skip for now',
                    style: AppFonts.body(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
