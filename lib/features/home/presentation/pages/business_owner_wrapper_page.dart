import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../../core/navigation/business_owner_navigation_wrapper.dart';
import '../../../auth/domain/entities/user.dart';
import '../bloc/business_owner_home_cubit.dart';
import '../bloc/business_owner_subscription_cubit.dart';
import '../bloc/notification_cubit.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import 'business_owner_onboarding_page.dart';

/// Wraps business owner flow with cubits and bottom nav (Home, Dash, Boosts, Messages, Profile).
class BusinessOwnerWrapperPage extends StatefulWidget {
  final User user;

  const BusinessOwnerWrapperPage({super.key, required this.user});

  @override
  State<BusinessOwnerWrapperPage> createState() => _BusinessOwnerWrapperPageState();
}

class _BusinessOwnerWrapperPageState extends State<BusinessOwnerWrapperPage> {
  late final LocalStorage _localStorage;
  bool _isCheckingOnboarding = true;
  bool _hasCompletedOnboarding = false;

  String get _storageKey =>
      '${StorageKeys.hasCompletedBusinessOwnerOnboarding}_${widget.user.id}';

  @override
  void initState() {
    super.initState();
    _localStorage = di.sl<LocalStorage>();
    _loadOnboardingStatus();
  }

  Future<void> _loadOnboardingStatus() async {
    final completed = await _localStorage.getBool(_storageKey) ?? false;
    if (!mounted) return;
    setState(() {
      _hasCompletedOnboarding = completed;
      _isCheckingOnboarding = false;
    });
  }

  Future<void> _completeOnboarding() async {
    await _localStorage.setBool(_storageKey, true);
    if (!mounted) return;
    setState(() {
      _hasCompletedOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingOnboarding) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasCompletedOnboarding) {
      return BusinessOwnerOnboardingPage(
        onContinue: _completeOnboarding,
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<BusinessOwnerHomeCubit>(),
        ),
        BlocProvider(
          create: (context) {
            final cubit = di.sl<BusinessOwnerSubscriptionCubit>();
            cubit.refresh(widget.user.id);
            return cubit;
          },
        ),
        BlocProvider(
          create: (_) => di.sl<NotificationCubit>(),
        ),
        BlocProvider(
          create: (_) => di.sl<DashboardCubit>(),
        ),
      ],
      child: BusinessOwnerNavigationWrapper(
        user: widget.user,
        initialIndex: 0,
      ),
    );
  }
}
