import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/onboarding_cubit.dart';
import '../bloc/onboarding_state.dart';
import '../../domain/entities/onboarding_page_data.dart';
import '../../../auth/presentation/pages/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding pages data
  final List<OnboardingPageData> _pages = [
    const OnboardingPageData(
      title: 'Discover Your Community',
      description: 'Find events, concerts, and cultural celebrations near you. Connect with Habesh community across America.',
      imageAsset: AppAssets.onboardingMusicFestival,
      pageIndex: 0,
    ),
    const OnboardingPageData(
      title: 'Support Local Businesses',
      description: 'Discover Ethiopian and Eritrean restaurants, shops, and services. Find deals and support your community.',
      imageAsset: AppAssets.onboardingCoffeeShop,
      pageIndex: 1,
    ),
    const OnboardingPageData(
      title: 'Grow Together',
      description: 'Find jobs, join community groups, and build lasting connections.',
      imageAsset: AppAssets.onboardingGrowTogether,
      pageIndex: 2,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppResources.onboardingTransitionDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    context.read<OnboardingCubit>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        } else if (state is OnboardingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: SafeArea(
          child: Column(
            children: [
              // Skip/Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppResources.spacingM),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: _onSkip,
                  ),
                ),
              ),

              // Progress indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildProgressIndicator(index == _currentPage),
                  ),
                ),
              ),

              const SizedBox(height: AppResources.spacingM),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_pages[index]);
                  },
                ),
              ),

              // Next/Get Started button
              Padding(
                padding: const EdgeInsets.all(AppResources.spacingL),
                child: SizedBox(
                  width: double.infinity,
                  height: AppResources.buttonHeightM,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: AppTextStyles.buttonText(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 4,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.progressActive : AppColors.progressInactive,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPageData pageData) {
    return Padding(
      padding: const EdgeInsets.all(AppResources.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Expanded(
            flex: 3,
            child: Image.asset(
              pageData.imageAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback placeholder
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppResources.radiusL),
                  ),
                  child: const Icon(
                    Icons.image,
                    size: 120,
                    color: AppColors.textTertiary,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppResources.spacingXL),

          // Title
          Text(
            pageData.title,
            style: AppTextStyles.largeTitle(context),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppResources.spacingM),

          // Description
          Text(
            pageData.description,
            style: AppTextStyles.bodyDescription(context),
            textAlign: TextAlign.center,
          ),

          // Tagline for last page
          if (pageData.pageIndex == 2) ...[
            const SizedBox(height: AppResources.spacingM),
            Text(
              '(Together we succeed)',
              style: AppTextStyles.bodyDescription(
                context,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
