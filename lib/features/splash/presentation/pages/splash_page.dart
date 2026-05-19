import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/services/app_version_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/force_update_page.dart';
import '../../../../injection/injection_container.dart' as di;
import '../bloc/splash_cubit.dart';
import '../bloc/splash_state.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../choose_path/presentation/pages/choose_path_page.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../home/presentation/pages/admin_home_page.dart';
import '../../../home/presentation/pages/business_owner_wrapper_page.dart';
import '../../../../core/subscription/subscription_logger.dart';
import '../../../home/presentation/pages/customer_home_page.dart';
import '../../../home/presentation/pages/guest_home_page.dart';

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
                  color: AppColors.brandPrimary.withValues(alpha: opacity.clamp(0.3, 1.0)),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }

  /// Returns true when a force-update screen was pushed (caller should stop
  /// navigating to the rest of the app).
  Future<bool> _maybeShowForceUpdate() async {
    try {
      final versionStatus = await di.sl<AppVersionService>().evaluate();
      if (!mounted) return true;
      if (versionStatus.mustUpdate) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ForceUpdatePage(status: versionStatus),
          ),
        );
        return true;
      }
    } catch (_) {
      // Never block startup on remote config errors.
    }
    return false;
  }

  void _navigateToNextScreen(SplashState state) {
    if (state is SplashLoaded) {
      final status = state.status;

      // Wait for splash duration before navigating
      Future.delayed(AppResources.splashScreenDuration, () async {
        if (!mounted) return;
        if (await _maybeShowForceUpdate()) return;
        if (!mounted) return;

        if (!status.hasCompletedOnboarding) {
          // Navigate to onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingPage()),
          );
        } else if (status.isAuthenticated) {
          final user = status.currentUser;
          if (user == null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ChoosePathPage()),
            );
            return;
          }
          // Restore auth + RevenueCat identity (subscriber attributes + store sync).
          await context.read<AuthCubit>().restoreUser(user);
          if (!mounted) return;
          subscriptionLog(
            'splash authenticated — userId=${user.id} role=${user.role.name}',
          );
          final Widget destination;
          switch (user.role) {
            case UserRole.businessOwner:
              subscriptionLog('splash → BusinessOwnerWrapperPage userId=${user.id}');
              destination = BusinessOwnerWrapperPage(user: user);
              break;
            case UserRole.admin:
              destination = AdminHomePage(user: user);
              break;
            case UserRole.guest:
              destination = GuestHomePage(user: user);
              break;
            case UserRole.customer:
              destination = CustomerHomePage(user: user);
              break;
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => destination),
          );
        } else {
          // Navigate to choose path (user not authenticated)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ChoosePathPage()),
          );
        }
      });
    } else if (state is SplashError) {
      // On error, navigate to choose path after delay
      Future.delayed(AppResources.splashScreenDuration, () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChoosePathPage()),
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                AppAssets.splashLogo,
                                width: AppResources.logoSizeSplash,
                                height: AppResources.logoSizeSplash,
                                errorBuilder: (context, error, stackTrace) {
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
          },
        ),
      ),
    );
  }
}
