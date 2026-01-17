import 'package:flutter/material.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import 'welcome_page.dart';

class Interest {
  final String name;
  final IconData icon;

  Interest({required this.name, required this.icon});
}

class InterestsSelectionPage extends StatefulWidget {
  const InterestsSelectionPage({super.key});

  @override
  State<InterestsSelectionPage> createState() => _InterestsSelectionPageState();
}

class _InterestsSelectionPageState extends State<InterestsSelectionPage> {
  final List<Interest> _interests = [
    Interest(name: 'Music & Concerts', icon: Icons.music_note),
    Interest(name: 'Food and Drinks', icon: Icons.restaurant),
    Interest(name: 'Jobs', icon: Icons.work),
    Interest(name: 'Community', icon: Icons.people),
    Interest(name: 'Shopping', icon: Icons.shopping_bag),
    Interest(name: 'Event and Nightlife', icon: Icons.celebration),
    Interest(name: 'Culture', icon: Icons.museum),
    Interest(name: 'Housing', icon: Icons.home),
  ];

  final Set<String> _selectedInterests = {};

  void _onContinue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const WelcomePage(),
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
          TextButton(
            onPressed: _onContinue,
            child: Text(
              'Skip',
              style: AppFonts.body(color: AppColors.brandPrimary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppResources.spacingL,
                vertical: AppResources.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'What interests you?',
                    style: AppFonts.largeTitle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),

            // Interests grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(AppResources.spacingL),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: AppResources.spacingM,
                  mainAxisSpacing: AppResources.spacingM,
                ),
                itemCount: _interests.length,
                itemBuilder: (context, index) {
                  final interest = _interests[index];
                  final isSelected = _selectedInterests.contains(interest.name);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedInterests.remove(interest.name);
                        } else {
                          _selectedInterests.add(interest.name);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(AppResources.radiusL),
                    child: Container(
                      padding: const EdgeInsets.all(AppResources.spacingM),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandPrimaryLight.withOpacity(0.1)
                            : AppColors.backgroundWhite,
                        border: Border.all(
                          color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(AppResources.radiusL),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon background
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.brandSecondary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  interest.icon,
                                  color: AppColors.textPrimary,
                                  size: AppResources.iconSizeL,
                                ),
                              ),
                              const SizedBox(height: AppResources.spacingM),
                              // Interest name
                              Text(
                                interest.name,
                                style: AppFonts.bodySmall(
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          // Selection indicator
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.brandPrimary : AppColors.backgroundWhite,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.brandPrimary : AppColors.backgroundGrey,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: AppColors.textOnPrimary,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(AppResources.spacingL),
              child: SizedBox(
                width: double.infinity,
                height: AppResources.buttonHeightM,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppFonts.button(color: AppColors.textOnPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
