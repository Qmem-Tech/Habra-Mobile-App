import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import 'welcome_page.dart';

class Interest {
  final String name;
  final IconData icon;

  Interest({required this.name, required this.icon});
}

class InterestsSelectionPage extends StatefulWidget {
  const InterestsSelectionPage({
    super.key,
    this.initialSelected = const [],
    this.onboardingFlow = true,
  });

  final List<String> initialSelected;
  final bool onboardingFlow;

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

  late final Set<String> _selectedInterests;

  @override
  void initState() {
    super.initState();
    _selectedInterests = widget.initialSelected.toSet();
  }

  Future<void> _persistInterests() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated || authState.user.isGuest) return;
    final selected = _selectedInterests.toList()..sort();
    await di.sl<ProfileRepository>().updateProfile(
          authState.user.id,
          UserProfileUpdate(interests: selected),
        );
  }

  Future<void> _onContinue() async {
    await _persistInterests();
    if (!mounted) return;
    if (widget.onboardingFlow) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const WelcomePage(),
        ),
      );
      return;
    }
    Navigator.of(context).pop(_selectedInterests.toList());
  }

  void _onSkip() {
    if (widget.onboardingFlow) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const WelcomePage(),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
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
          if (widget.onboardingFlow)
            TextButton(
              onPressed: _onSkip,
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
                  childAspectRatio: 0.9,
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
                            ? AppColors.brandPrimaryLight.withValues(alpha:0.1)
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Icon background
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.brandSecondary.withValues(alpha:0.2),
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
                              Expanded(
                                child: Center(
                                  child: Text(
                                    interest.name,
                                    style: AppFonts.bodySmall(
                                      color: AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                    padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppResources.radiusM),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppFonts.button(color: AppColors.textOnPrimary).copyWith(
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
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
