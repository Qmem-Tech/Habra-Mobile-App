import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/business_subscription_config.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/subscription/business_subscription_sync.dart';
import '../../../../core/subscription/subscription_logger.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../../core/navigation/business_owner_navigation_wrapper.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../bloc/business_owner_home_cubit.dart';
import '../bloc/business_owner_subscription_cubit.dart';
import '../bloc/notification_cubit.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import 'business_owner_first_listing_page.dart';
import 'business_owner_onboarding_page.dart';

/// Wraps business owner flow: intro onboarding, then either the empty-listing shell
/// or cubits + bottom nav (Home, Dash, Boosts, Profile).
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
  bool _isCheckingBusinesses = false;
  bool? _hasAtLeastOneBusiness;

  String get _storageKey =>
      '${StorageKeys.hasCompletedBusinessOwnerOnboarding}_${widget.user.id}';

  @override
  void initState() {
    super.initState();
    subscriptionLog(
      'BusinessOwnerWrapper init — userId=${widget.user.id} '
      'mode=${BusinessSubscriptionConfig.mode.name}',
    );
    _localStorage = di.sl<LocalStorage>();
    _loadOnboardingStatus();
  }

  Future<void> _loadOnboardingStatus() async {
    final completed = await _localStorage.getBool(_storageKey) ?? false;
    if (!mounted) return;
    setState(() {
      _hasCompletedOnboarding = completed;
      _isCheckingOnboarding = false;
      if (completed) {
        _isCheckingBusinesses = true;
        _hasAtLeastOneBusiness = null;
      }
    });
    if (completed) {
      await _loadBusinessPresence();
    }
  }

  Future<void> _loadBusinessPresence() async {
    try {
      final repo = di.sl<DashboardRepository>();
      final list = await repo.getOwnerBusinesses(widget.user.id);
      // Sync RC subscription state to Supabase BEFORE showing the main shell so
      // the home cubit loads with the already-updated subscription_tier.
      await _syncSubscriptionToDB();
      if (!mounted) return;
      setState(() {
        _hasAtLeastOneBusiness = list.isNotEmpty;
        _isCheckingBusinesses = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Fail open: full shell so the user is not stuck if the network fails.
      setState(() {
        _hasAtLeastOneBusiness = true;
        _isCheckingBusinesses = false;
      });
    }
  }

  Future<void> _syncSubscriptionToDB({bool forceRefresh = false}) async {
    subscriptionLog('startup sync — userId=${widget.user.id}');
    await BusinessSubscriptionSync.syncOwnerTierToDatabase(
      widget.user.id,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> _completeOnboarding() async {
    await _localStorage.setBool(_storageKey, true);
    if (!mounted) return;
    setState(() {
      _hasCompletedOnboarding = true;
      _isCheckingBusinesses = true;
      _hasAtLeastOneBusiness = null;
    });
    await _loadBusinessPresence();
  }

  Widget _buildOwnerMainShell() {
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
    if (_isCheckingBusinesses || _hasAtLeastOneBusiness == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasAtLeastOneBusiness == false) {
      return BusinessOwnerFirstListingPage(user: widget.user);
    }

    return _buildOwnerMainShell();
  }
}
