import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../injection/injection_container.dart' as di;
import '../../../auth/domain/entities/user.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/usecases/get_profile_usecase.dart';
import '../../../profile/presentation/bloc/edit_profile_cubit.dart';
import 'edit_profile_page.dart';

/// Profile tab: descriptive page with avatar, name, email, role, location, bio. Loads [UserProfile] for full details.
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppResources.spacingL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppFonts.body(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppResources.spacingM),
                        TextButton(
                          onPressed: _loadProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
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
                        const SizedBox(height: AppResources.spacingL),
                        Text(
                          'Welcome back',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: AppResources.spacingXS),
                        Text(
                          _profile?.fullName ?? widget.user.name,
                          style: AppFonts.mediumTitle(color: AppColors.textPrimary)
                              .copyWith(fontSize: 24),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppResources.spacingXL),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                    create: (_) => di.sl<EditProfileCubit>(),
                                    child: EditProfilePage(user: widget.user),
                                  ),
                                ),
                              ).then((_) => _loadProfile());
                            },
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
                          style: AppFonts.mediumTitle(color: AppColors.textPrimary),
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
                        const SizedBox(height: AppResources.spacingS),
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
                              style: AppFonts.bodySmall(
                                  color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        if (_profile?.location != null &&
                            _profile!.location!.isNotEmpty) ...[
                          const SizedBox(height: AppResources.spacingL),
                          Container(
                            padding: const EdgeInsets.all(AppResources.spacingM),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius:
                                  BorderRadius.circular(AppResources.radiusL),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 22,
                                  color: AppColors.brandPrimary,
                                ),
                                const SizedBox(width: AppResources.spacingS),
                                Expanded(
                                  child: Text(
                                    _profile!.location!,
                                    style: AppFonts.body(
                                        color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_profile?.bio != null &&
                            _profile!.bio!.isNotEmpty) ...[
                          const SizedBox(height: AppResources.spacingL),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'About',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(height: AppResources.spacingXS),
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
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppResources.spacingXL),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider(
                                  create: (_) => di.sl<EditProfileCubit>(),
                                  child: EditProfilePage(user: widget.user),
                                ),
                              ),
                            ).then((_) => _loadProfile());
                          },
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: const Text('Edit Profile'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
