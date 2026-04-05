import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/support_contact.dart';
import '../../../../core/utils/relative_time_short.dart';
import '../../../../core/navigation/business_owner_navigation_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/resources/app_assets.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/habra_circular_loader.dart';
import '../../../../core/widgets/notification_icon_with_badge.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/business_presence.dart';
import '../../domain/entities/owner_snapshot_metrics.dart';
import '../../domain/entities/owner_activity_item.dart';
import '../../domain/entities/setup_task.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/job.dart';
import '../bloc/business_owner_home_cubit.dart';
import '../bloc/business_owner_home_state.dart';
import '../bloc/business_owner_subscription_cubit.dart';
import '../widgets/business_owner_drawer.dart';
import '../widgets/owner_business_group_card.dart';
import '../../../dashboard/presentation/pages/edit_business_page.dart';
import '../../../dashboard/presentation/pages/update_hours_page.dart';
import '../../../dashboard/presentation/pages/create_deal_page.dart';
import '../../../dashboard/presentation/pages/create_job_post_page.dart';
import '../../../dashboard/presentation/pages/job_applicants_page.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart'
    show LegalDocumentsStatus;
import '../../../dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../../dashboard/presentation/widgets/business_gallery_photos_dialog.dart';
import '../../../dashboard/presentation/widgets/business_images_upload_dialog.dart';
import '../../../dashboard/presentation/widgets/choose_business_for_images_dialog.dart';
import '../../../dashboard/presentation/widgets/choose_business_for_legal_docs_dialog.dart';
import '../../../dashboard/presentation/widgets/legal_documents_upload_dialog.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import 'business_owner_notification_page.dart';
import 'add_new_presence_page.dart';
import 'my_businesses_page.dart';

class BusinessOwnerHomePage extends StatefulWidget {
  final User user;

  const BusinessOwnerHomePage({super.key, required this.user});

  @override
  State<BusinessOwnerHomePage> createState() => _BusinessOwnerHomePageState();
}

class _BusinessOwnerHomePageState extends State<BusinessOwnerHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _imagesDialogShownThisSession = false;
  bool _legalDocsDialogShownThisSession = false;
  bool _selectedBusinessMissingLegalDocs = false;
  bool _selectedBusinessLegalRejected = false;
  List<String> _selectedBusinessLegalRejectionReasons = [];
  bool _selectedBusinessLegalAwaitingReview = false;
  bool _selectedBusinessLegalDocsApproved = false;

  /// Session dismissals for home info banners (under review, legal pending, etc.).
  final Set<String> _dismissedHomeBannerKeys = <String>{};
  int _businessesNeedingLegalDocsCount = 0;
  String? _lastCheckedPresenceId;
  bool _checkingLegalDocsForPresence = false;

  @override
  void initState() {
    super.initState();
    context.read<BusinessOwnerHomeCubit>().loadOwnerHome(
          ownerId: widget.user.id,
          showSetupIncomplete: false,
        );
  }

  /// Shows post-login dialogs in sequence: images first, then legal documents.
  void _checkAndShowPostLoginDialogs(
    BuildContext context,
    BusinessOwnerHomeLoaded state,
  ) {
    if (_imagesDialogShownThisSession && _legalDocsDialogShownThisSession) return;

    final businesses = state.presences.where((p) => p.id != 'all').toList();
    if (businesses.isEmpty) return;

    final presencesNeedingImages = state.presences
        .where((p) => p.id != 'all' && !p.hasRequiredImages)
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;

      // Step 1: Images dialog (if needed)
      if (!_imagesDialogShownThisSession && presencesNeedingImages.isNotEmpty) {
        _imagesDialogShownThisSession = true;

        final selected = await showDialog<BusinessPresence>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ChooseBusinessForImagesDialog(presences: businesses),
        );

        if (!context.mounted) return;

        if (selected != null) {
          if (selected.hasRequiredImages) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${selected.displayName} already has logo and cover photo.'),
                backgroundColor: AppColors.success,
              ),
            );
          } else {
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider.value(
                value: context.read<DashboardCubit>(),
                child: BusinessImagesUploadDialog(
                  businessId: selected.id,
                  businessName: selected.name,
                  initialLogoUrl: selected.logoUrl,
                  initialBackgroundUrl: selected.backgroundUrl,
                  initialGalleryUrls: selected.imageUrls,
                ),
              ),
            );
            if (!context.mounted) return;
            if (result == true) {
              await _afterBusinessImagesSaved();
            }
          }
        }
      }

      if (!context.mounted) return;

      // Step 2: Legal documents dialog (if needed)
      if (_legalDocsDialogShownThisSession) return;

      _legalDocsDialogShownThisSession = true; // Claim early to avoid duplicate on reload

      List<String> idsNeedingDocs;
      try {
        idsNeedingDocs = await context.read<DashboardCubit>().getBusinessIdsNeedingLegalDocs(widget.user.id);
      } catch (_) {
        if (!context.mounted) return;
        _legalDocsDialogShownThisSession = false; // Allow retry on next load
        return;
      }

      if (!context.mounted) return;
      if (mounted) {
        setState(() {
          _businessesNeedingLegalDocsCount = idsNeedingDocs.length;
        });
      }
      if (idsNeedingDocs.isEmpty) return;

      final presencesNeedingDocs = businesses.where((p) => idsNeedingDocs.contains(p.id)).toList();
      if (presencesNeedingDocs.isEmpty) return;

      final selected = await showDialog<BusinessPresence>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChooseBusinessForLegalDocsDialog(presences: presencesNeedingDocs),
      );

      if (!context.mounted) return;

      if (selected == null) return;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BlocProvider.value(
          value: context.read<DashboardCubit>(),
          child: LegalDocumentsUploadDialog(
            businessId: selected.id,
            businessName: selected.name,
          ),
        ),
      );
      if (!context.mounted) return;
      if (result == true) {
        await _afterLegalDocumentsUploaded(selected.id);
      }
    });
  }

  /// Clears legal-doc presence cache, reloads home, syncs banners from Supabase, success toast.
  Future<void> _afterLegalDocumentsUploaded(String businessId) async {
    if (!mounted) return;
    setState(() {
      _lastCheckedPresenceId = null;
      _checkingLegalDocsForPresence = false;
    });
    if (!context.mounted) return;
    BusinessOwnerNavigationWrapper.invalidateBusinessToolsAccessCache(context);

    final dashboardCubit = context.read<DashboardCubit>();
    final homeCubit = context.read<BusinessOwnerHomeCubit>();

    try {
      final ids = await dashboardCubit.getBusinessIdsNeedingLegalDocs(widget.user.id);
      if (mounted) {
        setState(() => _businessesNeedingLegalDocsCount = ids.length);
      }
    } catch (_) {}

    await homeCubit.loadOwnerHome(
      ownerId: widget.user.id,
      showSetupIncomplete: false,
    );

    try {
      final status = await dashboardCubit.getLegalDocumentsStatus(businessId);
      if (!mounted) return;
      setState(() {
        _applyLegalStatusToSelectionState(status);
        _lastCheckedPresenceId = businessId;
        _dismissedHomeBannerKeys.remove('legal_pending_$businessId');
        _dismissedHomeBannerKeys.remove('legal_required_$businessId');
        _dismissedHomeBannerKeys.remove('legal_rejected_$businessId');
        _dismissedHomeBannerKeys.remove('legal_approved_$businessId');
      });
    } catch (_) {
      if (mounted) {
        setState(() => _lastCheckedPresenceId = null);
      }
    }

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: const Text(
            'Legal documents submitted successfully. We\'ll review them shortly.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  Future<void> _afterBusinessImagesSaved() async {
    await context.read<BusinessOwnerHomeCubit>().loadOwnerHome(
          ownerId: widget.user.id,
          showSetupIncomplete: false,
        );
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: const Text('Business photos updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _applyLegalStatusToSelectionState(LegalDocumentsStatus status) {
    _selectedBusinessMissingLegalDocs = status.missingInitialUpload;
    _selectedBusinessLegalRejected = status.hasRejected;
    _selectedBusinessLegalRejectionReasons = List<String>.from(status.rejectionReasons);
    _selectedBusinessLegalAwaitingReview = status.awaitingLegalDocReview;
    _selectedBusinessLegalDocsApproved = status.showLegalApprovalSuccess;
  }

  void _checkSelectedBusinessLegalDocs(BusinessOwnerHomeLoaded state) {
    final selected = state.selectedPresence;
    if (selected == null || selected.id == 'all') {
      if (_selectedBusinessMissingLegalDocs ||
          _selectedBusinessLegalAwaitingReview ||
          _selectedBusinessLegalRejected ||
          _selectedBusinessLegalDocsApproved ||
          _lastCheckedPresenceId != null) {
        setState(() {
          _selectedBusinessMissingLegalDocs = false;
          _selectedBusinessLegalAwaitingReview = false;
          _selectedBusinessLegalRejected = false;
          _selectedBusinessLegalRejectionReasons = [];
          _selectedBusinessLegalDocsApproved = false;
          _lastCheckedPresenceId = null;
        });
      }
      return;
    }
    if (_lastCheckedPresenceId == selected.id || _checkingLegalDocsForPresence) return;
    _checkingLegalDocsForPresence = true;
    _lastCheckedPresenceId = selected.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final status = await context.read<DashboardCubit>().getLegalDocumentsStatus(selected.id);
        if (!mounted) return;
        setState(() {
          _applyLegalStatusToSelectionState(status);
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _selectedBusinessMissingLegalDocs = false;
          _selectedBusinessLegalRejected = false;
          _selectedBusinessLegalRejectionReasons = [];
          _selectedBusinessLegalAwaitingReview = false;
          _selectedBusinessLegalDocsApproved = false;
        });
      } finally {
        _checkingLegalDocsForPresence = false;
      }
    });
  }

  Future<void> _openLegalDocsRequiredFlow() async {
    final state = context.read<BusinessOwnerHomeCubit>().state;
    if (state is! BusinessOwnerHomeLoaded) return;
    final selected = state.selectedPresence;
    if (selected != null && selected.id != 'all') {
      final status =
          await context.read<DashboardCubit>().getLegalDocumentsStatus(selected.id);
      if (!mounted) return;
      if (!status.needsOwnerAction) {
        final msg = status.showLegalApprovalSuccess
            ? 'Your legal documents are already approved.'
            : 'Legal documents are already submitted or under review. Upload again only if we rejected a file or asked for a replacement.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BlocProvider.value(
          value: context.read<DashboardCubit>(),
          child: LegalDocumentsUploadDialog(
            businessId: selected.id,
            businessName: selected.name,
          ),
        ),
      );
      if (!mounted) return;
      if (result == true) {
        await _afterLegalDocumentsUploaded(selected.id);
      }
      return;
    }

    final businesses = state.presences.where((p) => p.id != 'all').toList();
    if (businesses.isEmpty) return;
    final ids = await context.read<DashboardCubit>().getBusinessIdsNeedingLegalDocs(widget.user.id);
    final presencesNeedingDocs = businesses.where((p) => ids.contains(p.id)).toList();
    if (!mounted || presencesNeedingDocs.isEmpty) return;

    final selectedBusiness = await showDialog<BusinessPresence>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChooseBusinessForLegalDocsDialog(presences: presencesNeedingDocs),
    );
    if (!mounted || selectedBusiness == null) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<DashboardCubit>(),
        child: LegalDocumentsUploadDialog(
          businessId: selectedBusiness.id,
          businessName: selectedBusiness.name,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      await _afterLegalDocumentsUploaded(selectedBusiness.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ownerHomeSectionBg,
      key: _scaffoldKey,
      drawer: BlocBuilder<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
        builder: (context, state) {
          final selectedPresence =
              state is BusinessOwnerHomeLoaded ? state.selectedPresence : null;
          return BusinessOwnerDrawer(
            userId: widget.user.id,
            userName: widget.user.name,
            userEmail: widget.user.email,
            selectedBusiness: selectedPresence,
            showDashboardMenuItem:
                BusinessOwnerNavigationWrapper.drawerShowDashboardMenu(context),
            showBoostsMenuItem:
                BusinessOwnerNavigationWrapper.drawerShowBoostsMenu(context),
            onHomeTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 0),
            onDashboardTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 1),
            onBoostListingTap: () => BusinessOwnerNavigationWrapper.navigateToTab(context, 2),
            onEditBusinessTap: () async {
              if (state is! BusinessOwnerHomeLoaded) return;
              final loadedState = state;
              final presences = loadedState.presences
                  .where((p) => p.id != 'all')
                  .toList();
              if (presences.isEmpty) return;
              // Use scaffold context — drawer BlocBuilder's context can unmount
              // when the drawer closes, which breaks navigation after async picker.
              final navContext = _scaffoldKey.currentContext;
              if (navContext == null || !navContext.mounted) return;

              BusinessPresence targetPresence;
              if (presences.length == 1) {
                targetPresence = presences.first;
              } else {
                final selectedId = await Navigator.push<String?>(
                  navContext,
                  MaterialPageRoute(
                    builder: (_) => MyBusinessesPage(
                      presences: presences,
                      currentPresenceId: loadedState.selectedPresenceId,
                    ),
                  ),
                );
                final afterPicker = _scaffoldKey.currentContext;
                if (afterPicker == null ||
                    !afterPicker.mounted ||
                    selectedId == null) {
                  return;
                }
                final match = presences.where((p) => p.id == selectedId);
                if (match.isEmpty) return;
                targetPresence = match.first;
              }
              final forEdit = _scaffoldKey.currentContext;
              if (forEdit == null || !forEdit.mounted) return;
              final dashboardCubit = forEdit.read<DashboardCubit>();
              Navigator.push(
                forEdit,
                MaterialPageRoute(
                  builder: (_) => BlocProvider<DashboardCubit>.value(
                    value: dashboardCubit,
                    child: EditBusinessPage(business: targetPresence),
                  ),
                ),
              );
            },
            onBusinessPhotosTap: () async {
              if (state is! BusinessOwnerHomeLoaded) return;
              final loadedState = state;
              final presences =
                  loadedState.presences.where((p) => p.id != 'all').toList();
              if (presences.isEmpty) return;
              final navContext = _scaffoldKey.currentContext;
              if (navContext == null || !navContext.mounted) return;

              BusinessPresence targetPresence;
              if (presences.length == 1) {
                targetPresence = presences.first;
              } else {
                final selectedId = await Navigator.push<String?>(
                  navContext,
                  MaterialPageRoute(
                    builder: (_) => MyBusinessesPage(
                      presences: presences,
                      currentPresenceId: loadedState.selectedPresenceId,
                    ),
                  ),
                );
                final afterPicker = _scaffoldKey.currentContext;
                if (afterPicker == null ||
                    !afterPicker.mounted ||
                    selectedId == null) {
                  return;
                }
                final match = presences.where((p) => p.id == selectedId);
                if (match.isEmpty) return;
                targetPresence = match.first;
              }
              final dlgCtx = _scaffoldKey.currentContext;
              if (dlgCtx == null || !dlgCtx.mounted) return;
              final dashboardCubit = dlgCtx.read<DashboardCubit>();
              final result = await showDialog<List<String>?>(
                context: dlgCtx,
                builder: (_) => BlocProvider<DashboardCubit>.value(
                  value: dashboardCubit,
                  child: BusinessGalleryPhotosDialog(
                    businessId: targetPresence.id,
                    businessName: targetPresence.displayName,
                    initialImageUrls: targetPresence.imageUrls,
                  ),
                ),
              );
              if (!mounted || result == null) return;
              final homeCtx = _scaffoldKey.currentContext;
              if (homeCtx == null || !homeCtx.mounted) return;
              await homeCtx.read<BusinessOwnerHomeCubit>().loadOwnerHome(
                    ownerId: widget.user.id,
                    showSetupIncomplete: false,
                  );
            },
            onUpdateHoursTap: () {
              if (selectedPresence != null && selectedPresence.id != 'all') {
                final dashboardCubit = context.read<DashboardCubit>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider<DashboardCubit>.value(
                      value: dashboardCubit,
                      child: UpdateHoursPage(businessId: selectedPresence.id),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select a business first')),
                );
              }
            },
            onSettingsTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          );
        },
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<BusinessOwnerSubscriptionCubit,
                BusinessOwnerSubscriptionState>(
              builder: (context, subState) {
                if (!subState.shouldShowSubscribeBanner) {
                  return const SizedBox.shrink();
                }
                return Material(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppResources.spacingM,
                      vertical: AppResources.spacingS,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Subscribe to unlock the Dashboard and analytics.',
                            style:
                                AppFonts.bodySmall(color: AppColors.textPrimary),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              BusinessOwnerNavigationWrapper.openBusinessOwnerSubscription(
                            context,
                            widget.user,
                          ),
                          child: Text(
                            'Subscribe',
                            style: AppFonts.bodySmall(
                              color: AppColors.brandPrimary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              BusinessOwnerNavigationWrapper.navigateToTab(
                            context,
                            2,
                          ),
                          child: Text(
                            'Boosts',
                            style: AppFonts.bodySmall(
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<BusinessOwnerHomeCubit, BusinessOwnerHomeState>(
                builder: (context, state) {
                  if (state is BusinessOwnerHomeLoading) {
                    return const HabraCircularLoader(fullScreen: true);
                  }
                  if (state is BusinessOwnerHomeError) {
                    return _buildErrorView(state.message);
                  }
                  if (state is BusinessOwnerHomeLoaded) {
                    _checkAndShowPostLoginDialogs(context, state);
                    _checkSelectedBusinessLegalDocs(state);
                    if (state.isSetupIncomplete) {
                      return _buildSetupIncompleteView(state);
                    }
                    if (state.isAllBusinessesView) {
                      return _buildAllBusinessesView(state);
                    }
                    return _buildSingleBusinessView(state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BusinessOwnerHomeLoaded state, {
    required VoidCallback onBusinessSelectorTap,
  }) {
    final selected = state.selectedPresence;
    final label = selected != null
        ? '${selected.shortDisplayName}${selected.locationName != null ? " - ${selected.locationName}" : ""}'
        : 'All Businesses';

    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.backgroundWhite,
      toolbarHeight: 56,
      // Drawer would add a second hamburger; menu lives in [title] below.
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const Spacer(),
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
              ],
            ),
            GestureDetector(
              onTap: onBusinessSelectorTap,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 240),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.ownerHomeMintPill,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storefront,
                      size: 18,
                      color: AppColors.ownerHomePrimary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ownerHomePrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: AppColors.ownerHomePrimary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshOwnerHome(BuildContext context) async {
    await context.read<BusinessOwnerHomeCubit>().loadOwnerHome(
          ownerId: widget.user.id,
          showSetupIncomplete: false,
        );
  }

  Widget _buildSingleBusinessView(BusinessOwnerHomeLoaded state) {
    final presence = state.selectedPresence;

    return RefreshIndicator(
      onRefresh: () => _refreshOwnerHome(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
        _buildAppBar(state, onBusinessSelectorTap: _openBusinessLocations),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBusinessBanner(presence),
                    _buildBannerTitleRow(presence),
                  ],
                ),
              ),
              if (presence != null && presence.isPendingApproval)
                _buildUnderReviewNotice('under_review_${presence.id}'),
              if (_selectedBusinessLegalRejected && presence != null)
                _buildLegalDocsRejectedNotice(
                  dismissKey: 'legal_rejected_${presence.id}',
                  reasons: _selectedBusinessLegalRejectionReasons,
                ),
              if (_selectedBusinessMissingLegalDocs && presence != null)
                _buildLegalDocsRequiredNotice(
                  singleBusiness: true,
                  dismissKey: 'legal_required_${presence.id}',
                ),
              if (!_selectedBusinessMissingLegalDocs &&
                  !_selectedBusinessLegalRejected &&
                  _selectedBusinessLegalAwaitingReview &&
                  presence != null)
                _buildLegalDocsPendingReviewNotice(
                  'legal_pending_${presence.id}',
                ),
              if (_selectedBusinessLegalDocsApproved && presence != null)
                _buildLegalAndListingApprovedNotice(
                  dismissKey: 'legal_approved_${presence.id}',
                  presence: presence,
                ),
              Container(
                width: double.infinity,
                color: AppColors.ownerHomeSectionBg,
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  20,
                  AppResources.spacingM,
                  16,
                ),
                child: _buildSectionHeader(
                  'Today\'s Snapshot',
                  actionLabel: 'View Reports',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(
                    context,
                    1,
                    dashboardTab: 0,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.ownerHomeSectionBg,
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSnapshotCards(state.snapshot),
              ),
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  20,
                  AppResources.spacingM,
                  12,
                ),
                child: _buildSectionHeader('Quick Actions'),
              ),
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildQuickActions(),
              ),
              Container(
                width: double.infinity,
                color: AppColors.ownerHomeSectionBg,
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  8,
                  AppResources.spacingM,
                  12,
                ),
                child: _buildSectionHeader(
                  'Recent Activity',
                  actionLabel: 'View All',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(
                    context,
                    1,
                    dashboardTab: 4,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.ownerHomeSectionBg,
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  0,
                  AppResources.spacingM,
                  20,
                ),
                child: _buildRecentActivityList(
                  state.recentActivity,
                  onReplyToReview: () =>
                      BusinessOwnerNavigationWrapper.navigateToTab(
                    context,
                    1,
                    dashboardTab: 4,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  20,
                  AppResources.spacingM,
                  12,
                ),
                child: _buildSectionHeader(
                  'Your Active Deals',
                  actionLabel: 'Manage',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(
                    context,
                    1,
                    dashboardTab: 1,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildActiveDealsList(state.activeDeals),
              ),
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  16,
                  AppResources.spacingM,
                  12,
                ),
                child: _buildSectionHeader(
                  'Your Job Posts',
                  actionLabel: 'Manage',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(
                    context,
                    1,
                    dashboardTab: 2,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildJobPostsList(state.jobPosts),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildAllBusinessesView(BusinessOwnerHomeLoaded state) {
    return RefreshIndicator(
      onRefresh: () => _refreshOwnerHome(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
        _buildAppBar(state, onBusinessSelectorTap: _openBusinessLocations),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: AppColors.ownerHomeSectionBg,
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  20,
                  AppResources.spacingM,
                  12,
                ),
                child: _buildSectionHeader(
                  'This Month (All Businesses)',
                  actionLabel: 'View Reports',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(
                    context,
                    1,
                    dashboardTab: 0,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.ownerHomeSectionBg,
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSnapshotCards(state.snapshot),
              ),
              if (state.presences.any((presence) =>
                  presence.id != 'all' && presence.isPendingApproval))
                _buildUnderReviewNotice('under_review_all'),
              if (_businessesNeedingLegalDocsCount > 0)
                _buildLegalDocsRequiredNotice(
                  singleBusiness: false,
                  dismissKey: 'legal_required_all',
                ),
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  20,
                  AppResources.spacingM,
                  8,
                ),
                child: const Text(
                  'Your Businesses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
                child: _buildYourBusinessesList(state),
              ),
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppResources.spacingM,
                  vertical: 16,
                ),
                child: OwnerAddNewBusinessCtaButton(
                  onPressed: () => _openAddNewPresence(context),
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  8,
                  AppResources.spacingM,
                  12,
                ),
                child: _buildSectionHeader('Quick Actions'),
              ),
              Container(
                width: double.infinity,
                color: AppColors.backgroundWhite,
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildQuickActions(),
              ),
              Container(
                width: double.infinity,
                color: AppColors.ownerHomeSectionBg,
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  8,
                  AppResources.spacingM,
                  12,
                ),
                child: _buildSectionHeader(
                  'Recent Activity',
                  actionLabel: 'View All',
                  onActionTap: () => BusinessOwnerNavigationWrapper.navigateToTab(
                    context,
                    1,
                    dashboardTab: 4,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: AppColors.ownerHomeSectionBg,
                padding: const EdgeInsets.fromLTRB(
                  AppResources.spacingM,
                  0,
                  AppResources.spacingM,
                  32,
                ),
                child: _buildRecentActivityList(
                  state.recentActivity,
                  onReplyToReview: () =>
                      BusinessOwnerNavigationWrapper.navigateToTab(
                    context,
                    1,
                    dashboardTab: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildSetupIncompleteView(BusinessOwnerHomeLoaded state) {
    final completed = state.setupCompletedCount;
    final total = state.setupTasks.length;
    final progress = total > 0 ? completed / total : 0.0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: AppColors.backgroundWhite,
          toolbarHeight: 56,
          leading: const SizedBox.shrink(),
          leadingWidth: 0,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const Spacer(),
                    NotificationIconWithBadge(
                      userId: widget.user.id,
                      onOpenNotifications: () async {
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => BusinessOwnerNotificationPage(
                              userId: widget.user.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _openBusinessLocations,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ownerHomeMintPill,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront,
                          size: 18,
                          color: AppColors.ownerHomePrimary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            state.selectedPresence?.shortDisplayName ??
                                'My Business',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ownerHomePrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: AppColors.ownerHomePrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppResources.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Habra!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ) ?? const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s get your business set up for success in the Habesha community.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Setup Progress',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.progressInactive,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.progressActive),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completed of $total steps completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'To-Do List',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...state.setupTasks.asMap().entries.map((entry) {
                  final task = entry.value;
                  return _buildSetupTaskCard(
                    context,
                    task,
                    state: state,
                    isFirst: entry.key == 0,
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupTaskCard(
    BuildContext context,
    SetupTask task, {
    required BusinessOwnerHomeLoaded state,
    bool isFirst = false,
  }) {
    VoidCallback? onTap;
    VoidCallback? onButtonPressed;
    if (!task.isLocked) {
      switch (task.id) {
        case SetupTaskId.completeProfile:
          final presences = state.presences
              .where((p) => p.id != 'all')
              .toList();
          if (presences.isNotEmpty) {
            onTap = () async {
              BusinessPresence targetPresence;
              if (presences.length == 1) {
                targetPresence = presences.first;
              } else {
                final selectedId = await Navigator.push<String?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyBusinessesPage(
                      presences: presences,
                      currentPresenceId: state.selectedPresenceId,
                    ),
                  ),
                );
                if (!context.mounted || selectedId == null) return;
                final match = presences.where((p) => p.id == selectedId);
                if (match.isEmpty) return;
                targetPresence = match.first;
              }
              if (!context.mounted) return;
              final dashboardCubit = context.read<DashboardCubit>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider<DashboardCubit>.value(
                    value: dashboardCubit,
                    child: EditBusinessPage(business: targetPresence),
                  ),
                ),
              );
            };
          }
          break;
        case SetupTaskId.postFirstDeal:
          final presence = state.selectedPresence;
          if (presence != null && presence.id != 'all') {
            onTap = () {
              final dashboardCubit = context.read<DashboardCubit>();
              final homeCubit = context.read<BusinessOwnerHomeCubit>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider<DashboardCubit>.value(value: dashboardCubit),
                      BlocProvider<BusinessOwnerHomeCubit>.value(value: homeCubit),
                    ],
                    child: const CreateDealPage(),
                  ),
                ),
              );
            };
          }
          break;
        case SetupTaskId.shareListing:
          onTap = () => BusinessOwnerNavigationWrapper.navigateToTab(context, 2);
          break;
      }
      onButtonPressed = onTap;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(AppResources.spacingL),
        margin: EdgeInsets.zero,
        backgroundColor: isFirst
            ? AppColors.backgroundWhite
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
        onTap: task.isLocked ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: task.isLocked
                        ? AppColors.backgroundGrey
                        : AppColors.brandPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: task.isLocked
                        ? Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary)
                        : Text(
                            '${task.order}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandPrimary,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (isFirst && task.actionLabel != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: task.actionLabel!,
                            onPressed: onButtonPressed,
                            height: 44,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (task.isLocked)
                  const Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessBanner(BusinessPresence? presence) {
    if (presence == null) return const SizedBox.shrink();

    final coverUrl = (presence.backgroundUrl != null &&
            presence.backgroundUrl!.isNotEmpty)
        ? presence.backgroundUrl!
        : presence.imageUrl;
    final logoUrl = presence.logoUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        8,
        AppResources.spacingM,
        0,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 2.05,
                child: Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.backgroundGrey,
                    child: Image.asset(
                      AppAssets.businessOwnerCoverPlaceholder,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.store, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: -28,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        AppAssets.businessOwnerLogoPlaceholder,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      AppAssets.businessOwnerLogoPlaceholder,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerTitleRow(BusinessPresence? presence) {
    if (presence == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        40,
        AppResources.spacingM,
        4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.ownerOpenNowBadge,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: presence.isOpenNow
                        ? AppColors.ownerHomePrimary
                        : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  presence.isOpenNow ? 'Open Now' : 'Closed',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  presence.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (presence.isVerified)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.verified,
                    color: AppColors.brandSecondary,
                    size: 26,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                presence.category,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              if (presence.rating != null) ...[
                Text(
                  '  •  ',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textTertiary.withValues(alpha: 0.9),
                  ),
                ),
                Icon(Icons.star_rounded,
                    size: 18, color: AppColors.brandSecondary),
                const SizedBox(width: 4),
                Text(
                  '${presence.rating}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
          if (presence.isPendingApproval) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.ownerHomePrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.ownerHomePrimary.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule,
                      size: 16, color: AppColors.ownerHomePrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Pending for approval',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ownerHomePrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ownerHomePrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDismissibleHomeBanner({
    required String dismissKey,
    required Color backgroundColor,
    required Color borderColor,
    required EdgeInsetsGeometry outerPadding,
    required Widget child,
  }) {
    if (_dismissedHomeBannerKeys.contains(dismissKey)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: outerPadding,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          left: AppResources.spacingM,
          top: AppResources.spacingM,
          bottom: AppResources.spacingM,
          right: 4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppResources.radiusM),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child),
            IconButton(
              icon: Icon(Icons.close, size: 22, color: AppColors.textSecondary),
              tooltip: 'Dismiss',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              onPressed: () =>
                  setState(() => _dismissedHomeBannerKeys.add(dismissKey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnderReviewNotice(String dismissKey) {
    return _buildDismissibleHomeBanner(
      dismissKey: dismissKey,
      backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.08),
      borderColor: AppColors.brandPrimary.withValues(alpha: 0.25),
      outerPadding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        12,
        AppResources.spacingM,
        4,
      ),
      child: const Text(
        'Your documents were submitted successfully and are under review. We will notify you once approved.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }

  /// Shown when license (+ optional EIN) are on file but admin has not marked rows approved yet.
  Widget _buildLegalDocsPendingReviewNotice(String dismissKey) {
    return _buildDismissibleHomeBanner(
      dismissKey: dismissKey,
      backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.08),
      borderColor: AppColors.brandPrimary.withValues(alpha: 0.25),
      outerPadding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        8,
        AppResources.spacingM,
        4,
      ),
      child: const Text(
        'Your legal documents are on file and pending admin review. You do not need to upload again unless we ask you to replace a file.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildLegalDocsRequiredNotice({
    required bool singleBusiness,
    required String dismissKey,
  }) {
    final description = singleBusiness
        ? 'This business is missing required legal documents. Upload them to continue business owner flows.'
        : '$_businessesNeedingLegalDocsCount business account(s) still require legal documents. Please complete uploads.';
    return _buildDismissibleHomeBanner(
      dismissKey: dismissKey,
      backgroundColor: AppColors.warning.withValues(alpha: 0.12),
      borderColor: AppColors.warning.withValues(alpha: 0.35),
      outerPadding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        8,
        AppResources.spacingM,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legal documents required',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppResources.spacingXS),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppResources.spacingS),
          TextButton(
            onPressed: _openLegalDocsRequiredFlow,
            child: const Text('Upload documents now'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalDocsRejectedNotice({
    required String dismissKey,
    required List<String> reasons,
  }) {
    return _buildDismissibleHomeBanner(
      dismissKey: dismissKey,
      backgroundColor: AppColors.error.withValues(alpha: 0.08),
      borderColor: AppColors.error.withValues(alpha: 0.35),
      outerPadding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        8,
        AppResources.spacingM,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Document update required',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppResources.spacingS),
          const Text(
            'A reviewer could not accept your submission. Please upload corrected files.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: AppResources.spacingS),
            const Text(
              'Details from the reviewer:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            ...reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: AppColors.textSecondary)),
                    Expanded(
                      child: Text(
                        r,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppResources.spacingS),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: _openLegalDocsRequiredFlow,
                child: const Text('Upload replacement'),
              ),
              TextButton(
                onPressed: () => _openSupportEmail(
                  subject: 'Habra — legal document question',
                ),
                child: const Text('Contact support'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalAndListingApprovedNotice({
    required String dismissKey,
    required BusinessPresence presence,
  }) {
    final listingApproved =
        (presence.statusText ?? '').toLowerCase() == 'approved';
    final body = listingApproved
        ? 'Your legal documents are approved and your business listing is approved. You can use the dashboard, deals, jobs, and boosts as usual.'
        : 'Your legal documents are approved. If your business listing still shows as pending, it will update after our team completes the final listing review.';

    return _buildDismissibleHomeBanner(
      dismissKey: dismissKey,
      backgroundColor: Colors.green.shade50,
      borderColor: Colors.green.shade200,
      outerPadding: const EdgeInsets.fromLTRB(
        AppResources.spacingM,
        8,
        AppResources.spacingM,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  listingApproved ? 'You’re all set' : 'Documents approved',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppResources.spacingS),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: Colors.green.shade900,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSupportEmail({required String subject}) async {
    if (kSupportEmail.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Support email is not configured in the app build. Reach out through your usual Habra support channel.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      queryParameters: {'subject': subject},
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email us at $kSupportEmail'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email us at $kSupportEmail'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSnapshotCards(OwnerSnapshotMetrics snapshot) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              label: 'Views',
              icon: Icons.visibility_outlined,
              value: snapshot.viewsFormatted,
              changePercent: snapshot.viewsChangePercent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricCard(
              label: 'Clicks',
              icon: Icons.touch_app_outlined,
              value: snapshot.clicksFormatted,
              changePercent: snapshot.clicksChangePercent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricCard(
              label: 'Msgs',
              icon: Icons.chat_bubble_outline_rounded,
              value: snapshot.messagesFormatted,
              changePercent: snapshot.messagesChangePercent,
              isNegative: snapshot.messagesChangePercent < 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required IconData icon,
    required String value,
    required double changePercent,
    bool isNegative = false,
  }) {
    final color = isNegative ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isNegative ? Icons.trending_down : Icons.trending_up,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '${changePercent >= 0 ? '+' : ''}${changePercent.abs().round()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final state = context.read<BusinessOwnerHomeCubit>().state;
    final selectedPresence =
        state is BusinessOwnerHomeLoaded ? state.selectedPresence : null;
    final hasSpecificBusiness =
        selectedPresence != null && selectedPresence.id != 'all';

    const circleSize = 64.0;
    const iconSize = 28.0;

    Future<void> postDeal() async {
      if (!hasSpecificBusiness) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a business first')),
        );
        return;
      }
      final dashboardCubit = context.read<DashboardCubit>();
      final homeCubit = context.read<BusinessOwnerHomeCubit>();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<DashboardCubit>.value(value: dashboardCubit),
              BlocProvider<BusinessOwnerHomeCubit>.value(value: homeCubit),
            ],
            child: const CreateDealPage(),
          ),
        ),
      );
      if (!context.mounted) return;
      homeCubit.loadOwnerHome(ownerId: widget.user.id);
    }

    Future<void> postJob() async {
      if (!hasSpecificBusiness) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a business first')),
        );
        return;
      }
      final dashboardCubit = context.read<DashboardCubit>();
      final homeCubit = context.read<BusinessOwnerHomeCubit>();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<DashboardCubit>.value(value: dashboardCubit),
              BlocProvider<BusinessOwnerHomeCubit>.value(value: homeCubit),
            ],
            child: const CreateJobPostPage(),
          ),
        ),
      );
      if (!context.mounted) return;
      homeCubit.loadOwnerHome(ownerId: widget.user.id);
    }

    void promote() =>
        BusinessOwnerNavigationWrapper.navigateToTab(context, 2);

    void hours() {
      if (!hasSpecificBusiness) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a business first')),
        );
        return;
      }
      final dashboardCubit = context.read<DashboardCubit>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider<DashboardCubit>.value(
            value: dashboardCubit,
            child: UpdateHoursPage(businessId: selectedPresence.id),
          ),
        ),
      );
    }

    Widget action({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      required bool primary,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: primary
                          ? AppColors.ownerHomePrimary
                          : AppColors.ownerHomeQuickActionSecondary,
                      shape: BoxShape.circle,
                      boxShadow: primary
                          ? [
                              BoxShadow(
                                color: AppColors.ownerHomePrimary
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: primary
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          action(
            icon: Icons.sell_rounded,
            label: 'Post Deal',
            onTap: postDeal,
            primary: true,
          ),
          action(
            icon: Icons.work_outline_rounded,
            label: 'Post Job',
            onTap: postJob,
            primary: false,
          ),
          action(
            icon: Icons.campaign_outlined,
            label: 'Promote',
            onTap: promote,
            primary: false,
          ),
          action(
            icon: Icons.schedule_rounded,
            label: 'Hours',
            onTap: hours,
            primary: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(
    List<OwnerActivityItem> items, {
    VoidCallback? onReplyToReview,
  }) {
    final displayItems = items
        .take(BusinessOwnerHomeCubit.recentActivityHomeLimit)
        .toList(growable: false);
    if (displayItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppResources.spacingL,
          vertical: AppResources.spacingXL,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'No recent activity yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: displayItems.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          color: AppColors.ownerHomeSectionBg,
        ),
        itemBuilder: (context, index) {
          final item = displayItems[index];
          return _buildActivityCard(
            item,
            onReplyToReview: onReplyToReview,
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(
    OwnerActivityItem item, {
    VoidCallback? onReplyToReview,
  }) {
    IconData iconData;
    Color iconBg;
    Color iconColor;
    switch (item.type) {
      case OwnerActivityType.review:
        iconData = Icons.star_rounded;
        iconBg = AppColors.brandSecondary;
        iconColor = AppColors.textOnPrimary;
        break;
      case OwnerActivityType.applicant:
        iconData = Icons.person_rounded;
        iconBg = AppColors.info.withValues(alpha: 0.22);
        iconColor = AppColors.info;
        break;
      case OwnerActivityType.event:
        iconData = Icons.event_rounded;
        iconBg = AppColors.ownerHomeMintPill;
        iconColor = AppColors.ownerHomePrimary;
        break;
      default:
        iconData = Icons.notifications_outlined;
        iconBg = AppColors.ownerHomeQuickActionSecondary;
        iconColor = AppColors.textPrimary;
    }

    final timeAgo = formatShortTimeAgo(item.createdAt);
    final showTrailingAction =
        item.actionLabel != null && onReplyToReview != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppResources.spacingM,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.body != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.body!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (showTrailingAction)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: TextButton(
                onPressed: onReplyToReview,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ownerHomePrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  item.actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveDealsList(List<Deal> deals) {
    if (deals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
        child: Text(
          'No active deals.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      itemCount: deals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final deal = deals[index];
        final expiry = deal.expiryDate != null
            ? 'Expires in ${deal.expiryDate!.difference(DateTime.now()).inDays} days'
            : '';
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => BusinessOwnerNavigationWrapper.navigateToTab(
              context,
              1,
              dashboardTab: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textTertiary.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.ownerHomePrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sell_rounded,
                      color: AppColors.textOnPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (expiry.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            expiry,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobPostsList(List<Job> jobs) {
    if (jobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
        child: Text(
          'No job posts.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppResources.spacingM),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openJobApplicants(context, job),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textTertiary.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.ownerHomeQuickActionSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${job.postedDate != null ? "5" : "0"} Applicants waiting',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYourBusinessesList(BusinessOwnerHomeLoaded state) {
    final rest = state.presences.where((p) => p.id != 'all').toList();
    final byGroup = <String, List<BusinessPresence>>{};
    for (final p in rest) {
      final g = p.businessGroupName ?? p.name;
      byGroup.putIfAbsent(g, () => []).add(p);
    }
    final entries = byGroup.entries.toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppResources.spacingM),
      itemBuilder: (context, index) {
        final e = entries[index];
        return OwnerBusinessGroupCard(
          groupKey: e.key,
          locations: e.value,
          currentPresenceId: state.selectedPresenceId,
          onPresenceSelected: (id) {
            final match = state.presences.where((p) => p.id == id);
            if (match.isEmpty) return;
            _manageBusiness(match.first);
          },
        );
      },
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Error loading data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Retry',
              onPressed: () {
                context.read<BusinessOwnerHomeCubit>().loadOwnerHome(ownerId: widget.user.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBusinessLocations() async {
    final cubit = context.read<BusinessOwnerHomeCubit>();
    final state = cubit.state;
    final loaded = state is BusinessOwnerHomeLoaded ? state : null;
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => MyBusinessesPage(
          presences: loaded?.presences ?? const <BusinessPresence>[],
          currentPresenceId: loaded?.selectedPresenceId,
        ),
      ),
    );
    if (!context.mounted) return;
    if (result != null) {
      cubit.setSelectedPresenceId(result);
    }
  }

  void _openAddNewPresence(BuildContext context) {
    final cubit = context.read<BusinessOwnerHomeCubit>();
    final state = cubit.state;
    final presences =
        state is BusinessOwnerHomeLoaded ? state.presences : const <BusinessPresence>[];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddNewPresencePage(presences: presences),
      ),
    ).then((_) {
      if (context.mounted) {
        cubit.loadOwnerHome(ownerId: widget.user.id, showSetupIncomplete: false);
      }
    });
  }

  void _openJobApplicants(BuildContext context, Job job) {
    final dashboardCubit = context.read<DashboardCubit>();
    final homeCubit = context.read<BusinessOwnerHomeCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<DashboardCubit>.value(value: dashboardCubit),
            BlocProvider<BusinessOwnerHomeCubit>.value(value: homeCubit),
          ],
          child: JobApplicantsPage(
            jobId: job.id,
            jobTitle: job.title,
            jobSubtitle: '${job.jobType} • ${job.location ?? job.companyName}',
          ),
        ),
      ),
    );
  }

  void _manageBusiness(BusinessPresence p) {
    context.read<BusinessOwnerHomeCubit>().setSelectedPresenceId(p.id);
    BusinessOwnerNavigationWrapper.navigateToTab(context, 1, dashboardTab: 0);
  }
}
