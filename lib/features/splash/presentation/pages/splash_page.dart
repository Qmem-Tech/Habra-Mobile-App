import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habra_mobile_app/features/auth/domain/entities/user.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/splash_cubit.dart';
import '../bloc/splash_state.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../home/presentation/pages/customer_home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _loadingDotsController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeSplash();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: AppResources.durationSlow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Loading dots animation controller (loops continuously)
    _loadingDotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animationController.forward();
  }

  void _initializeSplash() {
    // Trigger splash status check
    context.read<SplashCubit>().checkSplashStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadingDotsController.dispose();
    super.dispose();
  }

  Widget _buildLoadingDots() {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _loadingDotsController,
            builder: (context, child) {
              // Create staggered animation for each dot
              final delay = index * 0.2;
              final animationValue = ((_loadingDotsController.value + delay) % 1.0);
              final opacity = (animationValue < 0.5)
                  ? animationValue * 2
                  : 2 - (animationValue * 2);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withOpacity(opacity.clamp(0.3, 1.0)),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }

  void _navigateToNextScreen(SplashState state) {
    if (state is SplashLoaded) {
      final status = state.status;

      // Wait for splash duration before navigating
      Future.delayed(AppResources.splashScreenDuration, () {
        if (!mounted) return;

        if (!status.hasCompletedOnboarding) {
          // Navigate to onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingPage()),
          );
        } else if (status.isAuthenticated) {
          // Navigate to appropriate home based on user role
          // For now, default to customer home
          // This can be enhanced to check user role
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CustomerHomePage(user: User(id: 'id', email: 'abec@gmail.com', name: "Abel", role: UserRole.customer),)),
          );
        } else {
          // Navigate to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      });
    } else if (state is SplashError) {
      // On error, navigate to login after delay
      Future.delayed(AppResources.splashScreenDuration, () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        _navigateToNextScreen(state);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      Image.asset(
                        AppAssets.splashLogo,
                        width: AppResources.logoSizeSplash,
                        height: AppResources.logoSizeSplash,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if asset not found
                          return Container(
                            width: AppResources.logoSizeSplash,
                            height: AppResources.logoSizeSplash,
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people,
                              color: AppColors.textOnPrimary,
                              size: 60,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppResources.spacingL),
                      // App Name
                      Text(
                        'Habra',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ) ??
                            const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandPrimary,
                            ),
                      ),
                      const SizedBox(height: AppResources.spacingXL),
                      // Loading dots
                      _buildLoadingDots(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
