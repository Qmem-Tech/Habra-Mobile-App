import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../auth/domain/entities/user.dart';
import '../../../dashboard/presentation/pages/business_legal_documents_hub_page.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/usecases/get_profile_usecase.dart';
import '../../../profile/presentation/bloc/edit_profile_cubit.dart';
import 'edit_profile_page.dart';

/// Profile tab: avatar, identity, role, optional compliance entry for business owners.
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

  static String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Community member';
      case UserRole.businessOwner:
        return 'Business owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.guest:
        return 'Guest';
    }
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

  @override
  Widget build(BuildContext context) {
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ProfileErrorView(message: _error!, onRetry: _loadProfile)
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppResources.spacingL,
                      vertical: AppResources.spacingM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppResources.spacingM),
                        Text(
                          'Account',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                        ),
                        const SizedBox(height: AppResources.spacingL),
                        Center(
                          child: GestureDetector(
                            onTap: _openEditProfile,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 52,
                                  backgroundColor:
                                      AppColors.brandPrimary.withValues(alpha: 0.2),
                                  backgroundImage: _profile?.avatarUrl != null &&
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
                                          style: AppFonts.largeTitle(
                                                  color: AppColors.brandPrimary)
                                              .copyWith(fontSize: 36),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPrimary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.backgroundWhite,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppResources.spacingL),
                        Text(
                          _profile?.fullName ?? widget.user.name,
                          style: AppFonts.mediumTitle(color: AppColors.textPrimary)
                              .copyWith(fontSize: 22),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppResources.spacingXS),
                        Text(
                          widget.user.email,
                          style: AppFonts.body(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_profile?.phone != null && _profile!.phone!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppResources.spacingM),
                          _InfoTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: _profile!.phone!.trim(),
                          ),
                        ],
                        if (_profile?.createdAt != null) ...[
                          const SizedBox(height: AppResources.spacingS),
                          _InfoTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Member since',
                            value: DateFormat.yMMMMd().format(
                              _profile!.createdAt!.toLocal(),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppResources.spacingM),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppResources.spacingM,
                              vertical: AppResources.spacingS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundGrey.withValues(alpha: 0.5),
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusM),
                            ),
                            child: Text(
                              _roleLabel(widget.user.role),
                              style: AppFonts.bodySmall(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        if (widget.user.isBusinessOwner) ...[
                          const SizedBox(height: AppResources.spacingXL),
                          Text(
                            'Business',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                          ),
                          const SizedBox(height: AppResources.spacingS),
                          Material(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(AppResources.radiusL),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppResources.spacingM,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.brandPrimary.withValues(alpha: 0.12),
                                child: Icon(
                                  Icons.folder_shared_outlined,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                              title: Text(
                                'Legal & compliance',
                                style: AppFonts.body(color: AppColors.textPrimary)
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'View uploaded documents and review status',
                                style: AppFonts.bodySmall(color: AppColors.textSecondary),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                              onTap: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => BusinessLegalDocumentsHubPage(
                                      ownerId: widget.user.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        if (_profile?.location != null &&
                            _profile!.location!.isNotEmpty) ...[
                          const SizedBox(height: AppResources.spacingXL),
                          Text(
                            'Location',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AppResources.spacingS),
                          _InfoTile(
                            icon: Icons.location_on_outlined,
                            label: '',
                            value: _profile!.location!,
                          ),
                        ],
                        if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
                          const SizedBox(height: AppResources.spacingXL),
                          Text(
                            'About',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AppResources.spacingS),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppResources.spacingM),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusL),
                            ),
                            child: Text(
                              _profile!.bio!,
                              style: AppFonts.body(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppResources.spacingXL),
                        TextButton.icon(
                          onPressed: _openEditProfile,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: const Text('Edit profile'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brandPrimary,
                          ),
                        ),
                        const SizedBox(height: AppResources.spacingL),
                      ],
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppResources.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppResources.radiusL),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.brandPrimary),
          const SizedBox(width: AppResources.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty) ...[
                  Text(
                    label,
                    style: AppFonts.bodySmall(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  value,
                  style: AppFonts.body(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
