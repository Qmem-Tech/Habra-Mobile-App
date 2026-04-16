import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habra_mobile_app/l10n/app_localizations.dart';

import '../../../../core/constants/boost_plan_target.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/notification_icon_with_badge.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../auth/domain/entities/user.dart';
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../explore/presentation/pages/business_detail_page.dart';
import '../../../dashboard/presentation/pages/boost_listing_page.dart';
import '../../../dashboard/presentation/pages/edit_business_details_page.dart';
import '../../../dashboard/presentation/pages/operating_hours_page.dart';
import '../../domain/entities/business_presence.dart';
import '../bloc/business_owner_home_cubit.dart';
import '../bloc/business_owner_home_state.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/usecases/get_profile_usecase.dart';
import '../../../profile/presentation/bloc/edit_profile_cubit.dart';
import '../../../settings/presentation/widgets/account_settings_body.dart';
import 'business_owner_notification_page.dart';
import 'edit_profile_page.dart';
import 'location_map_page.dart';
import 'manage_business_photos_page.dart';
import 'my_businesses_page.dart';
import 'notification_preferences_page.dart';
import 'subscription_billing_page.dart';

/// Profile tab: for owners, listing-centric hub; for others, personal account.
class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await di.sl<GetProfileUseCase>().call(widget.user.id);
      if (!mounted) return;
      result.fold(
        (failure) => setState(() {
          _loading = false;
          _error = failure.message;
        }),
        (profile) => setState(() {
          _loading = false;
          _profile = profile;
        }),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _refreshAll() async {
    await _loadProfile();
    if (!mounted || !widget.user.isBusinessOwner) return;
    await context.read<BusinessOwnerHomeCubit>().loadOwnerHome(
          ownerId: widget.user.id,
          showSetupIncomplete: false,
        );
  }

  Future<void> _openEditProfile() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<EditProfileCubit>(),
          child: EditProfilePage(user: widget.user),
        ),
      ),
    );
    if (mounted) await _loadProfile();
  }

  BusinessPresence? _focusPresence(BusinessOwnerHomeLoaded state) {
    final id = state.focusBusinessIdForOwnerTools;
    if (id == null) return null;
    try {
      return state.presences.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  String _businessSelectorLabel(BusinessOwnerHomeLoaded state) {
    final selected = state.selectedPresence;
    if (state.isAllBusinessesView || selected == null) {
      return 'All businesses';
    }
    return '${selected.shortDisplayName}'
        '${selected.locationName != null ? ' - ${selected.locationName}' : ''}';
  }

  Future<void> _openMyBusinesses(BusinessOwnerHomeLoaded state) async {
    final id = await Navigator.push<String?>(
      context,
      MaterialPageRoute<String?>(
        builder: (_) => MyBusinessesPage(
          presences: state.presences,
          currentPresenceId: state.selectedPresenceId,
        ),
      ),
    );
    if (!mounted) return;
    if (id != null) {
      context.read<BusinessOwnerHomeCubit>().selectPresence(id);
    }
    await context.read<BusinessOwnerHomeCubit>().loadOwnerHome(
          ownerId: widget.user.id,
          showSetupIncomplete: false,
        );
  }

  Future<void> _afterOwnerToolRoute(Future<dynamic> navigation) async {
    await navigation;
    if (!mounted) return;
    await context.read<BusinessOwnerHomeCubit>().loadOwnerHome(
          ownerId: widget.user.id,
          showSetupIncomplete: false,
        );
  }

  static String _formatHhmmToAmPm(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final amPm = h < 12 ? 'AM' : 'PM';
    return '$hour12:${m.toString().padLeft(2, '0')} $amPm';
  }

  static Future<String> _todayHoursSubtitle(
    DashboardCubit cubit,
    String businessId,
  ) async {
    final hours = await cubit.getBusinessHours(businessId);
    if (hours == null) return 'Tap to set hours';
    final wd = DateTime.now().weekday;
    final wh = hours['weekly_hours'];
    Map<String, dynamic>? wm;
    if (wh is Map<String, dynamic>) {
      wm = wh;
    } else if (wh is Map) {
      wm = Map<String, dynamic>.from(wh);
    }
    final dayKey = '$wd';
    final raw = wm?[dayKey] ?? wm?[wd.toString()];
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      if (m['closed'] == true) return 'Closed today';
      final o = m['open']?.toString() ?? hours['opening_time']?.toString() ?? '09:00';
      final c = m['close']?.toString() ?? hours['closing_time']?.toString() ?? '17:00';
      return 'Open today: ${_formatHhmmToAmPm(o)} – ${_formatHhmmToAmPm(c)}';
    }
    final o = hours['opening_time']?.toString() ?? '09:00';
    final c = hours['closing_time']?.toString() ?? '17:00';
    return 'Open today: ${_formatHhmmToAmPm(o)} – ${_formatHhmmToAmPm(c)}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.isBusinessOwner) {
      return BlocBuilder<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
        builder: (context, homeState) {
          if (homeState is BusinessOwnerHomeLoading ||
              homeState is BusinessOwnerHomeInitial) {
            return Scaffold(
              backgroundColor: AppColors.backgroundWhite,
              appBar: AppBar(
                title: Text(
                  'Profile',
                  style: AppFonts.mediumTitle(color: AppColors.textPrimary),
                ),
                backgroundColor: AppColors.backgroundWhite,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (homeState is BusinessOwnerHomeError) {
            return Scaffold(
              backgroundColor: AppColors.backgroundWhite,
              appBar: AppBar(
                title: Text(
                  'Profile',
                  style: AppFonts.mediumTitle(color: AppColors.textPrimary),
                ),
                backgroundColor: AppColors.backgroundWhite,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
              ),
              body: _ProfileErrorView(
                message: homeState.message,
                onRetry: () => context.read<BusinessOwnerHomeCubit>().loadOwnerHome(
                      ownerId: widget.user.id,
                      showSetupIncomplete: false,
                    ),
              ),
            );
          }
          if (homeState is! BusinessOwnerHomeLoaded) {
            return const SizedBox.shrink();
          }
          return _buildBusinessOwnerScaffold(context, homeState);
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: AppFonts.mediumTitle(color: AppColors.textPrimary)
              .copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ProfileErrorView(message: _error!, onRetry: _loadProfile)
              : RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: AccountSettingsBody(
                    user: widget.user,
                    displayNameOverride: _profile?.fullName,
                    avatarUrlOverride: _profile?.avatarUrl,
                    onReturnedFromEditProfile: _loadProfile,
                  ),
                ),
    );
  }

  Widget _buildBusinessOwnerScaffold(
    BuildContext context,
    BusinessOwnerHomeLoaded homeState,
  ) {
    final focus = _focusPresence(homeState);
    final realCount = homeState.presences.where((p) => p.id != 'all').length;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: realCount == 0 ? null : () => _openMyBusinesses(homeState),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront, size: 18, color: AppColors.brandPrimary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _businessSelectorLabel(homeState),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (realCount > 0)
                  const Icon(Icons.arrow_drop_down,
                      size: 20, color: AppColors.brandPrimary),
              ],
            ),
          ),
        ),
        actions: [
          NotificationIconWithBadge(
            userId: widget.user.id,
            onOpenNotifications: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      BusinessOwnerNotificationPage(userId: widget.user.id),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (focus != null) _buildOwnerHero(context, focus),
                        if (focus == null) _buildNoListingPlaceholder(context),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppResources.spacingM,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppResources.spacingM),
                              const _OwnerSectionHeader(title: 'My Businesses'),
                              _OwnerMenuTile(
                                icon: Icons.business_outlined,
                                title: 'My Businesses',
                                subtitle: 'Manage all your businesses & locations',
                                onTap: realCount == 0
                                    ? () {}
                                    : () => _openMyBusinesses(homeState),
                              ),
                              const _OwnerSectionHeader(title: 'Boost Your Business'),
                              _OwnerMenuTile(
                                icon: Icons.auto_awesome_outlined,
                                title: 'Boost My Listing',
                                subtitle: 'Get featured & more views',
                                onTap: () {
                                  if (focus == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Choose a business from the header first, or add a listing under My Businesses.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  _afterOwnerToolRoute(
                                    Navigator.push<void>(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => BlocProvider.value(
                                          value: context.read<DashboardCubit>(),
                                          child: BoostListingPage(
                                            boostType:
                                                BoostPlanTarget.businessListing,
                                            selectedId: focus.id,
                                            selectedTitle: focus.displayName,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (focus != null) ...[
                                _OwnerSectionHeader(
                                  title:
                                      'Business info (for: ${focus.displayName})',
                                ),
                                _OwnerMenuTile(
                                  icon: Icons.edit_outlined,
                                  title: 'Edit details',
                                  subtitle: 'Name, category, description',
                                  onTap: () => _afterOwnerToolRoute(
                                    Navigator.push<dynamic>(
                                      context,
                                      MaterialPageRoute<dynamic>(
                                        builder: (_) => BlocProvider.value(
                                          value: context.read<DashboardCubit>(),
                                          child: EditBusinessDetailsPage(
                                            business: focus,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _OwnerMenuTile(
                                  icon: Icons.visibility_outlined,
                                  title: 'View public listing',
                                  subtitle: 'How customers see this business',
                                  onTap: () {
                                    Navigator.push<void>(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => BusinessDetailPage(
                                          businessId: focus.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _OwnerMenuTile(
                                  icon: Icons.photo_library_outlined,
                                  title: 'Manage photos',
                                  subtitle: 'Gallery and cover images',
                                  onTap: () => _afterOwnerToolRoute(
                                    Navigator.push<dynamic>(
                                      context,
                                      MaterialPageRoute<dynamic>(
                                        builder: (_) => BlocProvider.value(
                                          value: context.read<DashboardCubit>(),
                                          child: ManageBusinessPhotosPage(
                                            business: focus,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                FutureBuilder<String>(
                                  key: ValueKey<String>(focus.id),
                                  future: _todayHoursSubtitle(
                                    context.read<DashboardCubit>(),
                                    focus.id,
                                  ),
                                  builder: (context, snap) {
                                    final sub = snap.connectionState ==
                                            ConnectionState.waiting
                                        ? 'Loading hours…'
                                        : (snap.data ?? 'Tap to set hours');
                                    return _OwnerMenuTile(
                                      icon: Icons.schedule_outlined,
                                      title: 'Operating hours',
                                      subtitle: sub,
                                      onTap: () => _afterOwnerToolRoute(
                                        Navigator.push<dynamic>(
                                          context,
                                          MaterialPageRoute<dynamic>(
                                            builder: (_) => BlocProvider.value(
                                              value: context
                                                  .read<DashboardCubit>(),
                                              child: OperatingHoursPage(
                                                businessId: focus.id,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _OwnerMenuTile(
                                  icon: Icons.map_outlined,
                                  title: 'Location & map',
                                  subtitle: _addressSubtitle(focus),
                                  onTap: () {
                                    Navigator.push<void>(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            LocationMapPage(business: focus),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              const _OwnerSectionHeader(title: 'Account'),
                              _OwnerMenuTile(
                                icon: Icons.verified_user_outlined,
                                title: 'Verification status',
                                subtitle: focus?.isVerified ?? false
                                    ? 'Your listing is verified'
                                    : 'Complete verification when prompted',
                                trailing: _VerificationBadge(
                                  verified: focus?.isVerified ?? false,
                                ),
                                onTap: () {},
                                interactive: false,
                              ),
                              _OwnerMenuTile(
                                icon: Icons.payment_outlined,
                                title: 'Subscription & billing',
                                subtitle: 'Plans and receipts',
                                onTap: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => SubscriptionBillingPage(
                                        user: widget.user,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _OwnerMenuTile(
                                icon: Icons.notifications_outlined,
                                title: 'Notification preferences',
                                subtitle: 'How we contact you',
                                onTap: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          NotificationPreferencesPage(
                                        userId: widget.user.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: AppResources.spacingM),
                              Text(
                                'Personal profile',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                              const SizedBox(height: AppResources.spacingS),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.brandPrimary
                                      .withValues(alpha: 0.12),
                                  backgroundImage:
                                      _profile?.avatarUrl != null &&
                                              _profile!.avatarUrl!.isNotEmpty
                                          ? NetworkImage(_profile!.avatarUrl!)
                                          : null,
                                  child: _profile?.avatarUrl == null ||
                                          _profile!.avatarUrl!.isEmpty
                                      ? Text(
                                          (widget.user.name.isNotEmpty
                                                  ? widget.user.name[0]
                                                  : widget.user.email.isNotEmpty
                                                      ? widget.user.email[0]
                                                      : '?')
                                              .toUpperCase(),
                                          style: AppFonts.body(
                                            color: AppColors.brandPrimary,
                                          ).copyWith(fontWeight: FontWeight.w700),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  _profile?.fullName ?? widget.user.name,
                                  style: AppFonts.body(color: AppColors.textPrimary)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  widget.user.email,
                                  style: AppFonts.bodySmall(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _openEditProfile,
                              ),
                              const SizedBox(height: AppResources.spacingXL),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  static String _addressSubtitle(BusinessPresence p) {
    final street = p.locationName?.trim();
    if (street != null && street.isNotEmpty) return street;
    return p.locationDisplay;
  }

  Widget _buildNoListingPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppResources.spacingL),
      child: Column(
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppResources.spacingM),
          Text(
            'No businesses yet',
            style: AppFonts.mediumTitle(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppResources.spacingS),
          Text(
            'Add a listing from Home to manage it here.',
            style: AppFonts.body(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerHero(BuildContext context, BusinessPresence p) {
    final bg = (p.backgroundUrl != null && p.backgroundUrl!.isNotEmpty)
        ? p.backgroundUrl!
        : (p.imageUrl.isNotEmpty ? p.imageUrl : null);
    final logo = (p.logoUrl != null && p.logoUrl!.isNotEmpty)
        ? p.logoUrl!
        : (p.imageUrl.isNotEmpty ? p.imageUrl : null);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: bg != null
                  ? Image.network(
                      bg,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.backgroundLight,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textTertiary,
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.backgroundLight,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textTertiary,
                        size: 40,
                      ),
                    ),
            ),
            Positioned(
              bottom: -36,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.backgroundWhite, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.backgroundLight,
                  backgroundImage: logo != null ? NetworkImage(logo) : null,
                  child: logo == null
                      ? Icon(Icons.storefront,
                          color: AppColors.textTertiary, size: 40)
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 44),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
          child: Text(
            p.name,
            style: AppFonts.mediumTitle(color: AppColors.textPrimary)
                .copyWith(fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: AppResources.spacingS),
        _OwnerRatingRow(rating: p.rating, reviewCount: p.reviewCount),
        const SizedBox(height: AppResources.spacingM),
      ],
    );
  }

}

class _OwnerRatingRow extends StatelessWidget {
  const _OwnerRatingRow({
    required this.rating,
    required this.reviewCount,
  });

  final double? rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final r = (rating ?? 0).clamp(0.0, 5.0);
    final stars = <Widget>[];
    for (var i = 1; i <= 5; i++) {
      if (r >= i - 0.25) {
        stars.add(const Icon(Icons.star, size: 18, color: Color(0xFFFFB800)));
      } else if (r >= i - 0.75) {
        stars.add(const Icon(Icons.star_half, size: 18, color: Color(0xFFFFB800)));
      } else {
        stars.add(Icon(Icons.star_border, size: 18, color: AppColors.textTertiary));
      }
    }
    final label = rating != null ? rating!.toStringAsFixed(1) : '—';
    final n = reviewCount ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...stars,
        const SizedBox(width: 8),
        Text(
          '$label ($n reviews)',
          style: AppFonts.bodySmall(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _OwnerSectionHeader extends StatelessWidget {
  const _OwnerSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppResources.spacingL, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: AppFonts.bodySmall(color: AppColors.textSecondary)
              .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: verified
            ? AppColors.brandPrimary.withValues(alpha: 0.15)
            : AppColors.backgroundGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        verified ? 'VERIFIED' : 'PENDING',
        style: AppFonts.bodySmall(
          color: verified ? AppColors.brandPrimary : AppColors.textSecondary,
        ).copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _OwnerMenuTile extends StatelessWidget {
  const _OwnerMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.interactive = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppResources.radiusL),
          onTap: interactive ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppResources.spacingM,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.brandPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.body(color: AppColors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppFonts.bodySmall(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppResources.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: AppResources.spacingM),
            Text(
              'Couldn’t load your profile',
              textAlign: TextAlign.center,
              style: AppFonts.mediumTitle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppResources.spacingS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.body(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppResources.spacingL),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
