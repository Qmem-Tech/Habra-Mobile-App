import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../choose_path/presentation/pages/choose_path_page.dart';

/// Delete account + log out actions shared by community settings and business profile.
class AccountDangerZone extends StatefulWidget {
  const AccountDangerZone({
    super.key,
    required this.user,
  });

  final User user;

  @override
  State<AccountDangerZone> createState() => _AccountDangerZoneState();
}

class _AccountDangerZoneState extends State<AccountDangerZone> {
  bool _busy = false;

  bool get _isBusinessOwner => widget.user.isBusinessOwner;

  Future<void> _confirmDeleteAccount() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_busy,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          _isBusinessOwner
              ? 'This permanently deletes your account, business listings, events, and related data. This cannot be undone.'
              : 'This permanently deletes your account, tickets, and personal data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final cubit = context.read<AuthCubit>();
    final ok = await cubit.deleteAccount();
    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const ChoosePathPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
      return;
    }

    final state = cubit.state;
    final message = state is AuthError
        ? state.message
        : 'Could not delete account. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _logout() {
    if (_busy) return;
    context.read<AuthCubit>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ChoosePathPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(title: 'Account'),
        _SettingsCard(
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _busy ? null : _confirmDeleteAccount,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppResources.spacingM,
                      vertical: AppResources.spacingM,
                    ),
                    child: Row(
                      children: [
                        const _IconBadge(
                          icon: Icons.person_remove_outlined,
                          tint: AppColors.error,
                        ),
                        const SizedBox(width: AppResources.spacingS),
                        Expanded(
                          child: Text(
                            'Delete account',
                            style: AppFonts.body(color: AppColors.error)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_busy)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.error.withValues(alpha: 0.7),
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: AppColors.backgroundGrey.withValues(alpha: 0.6),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _busy ? null : _logout,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppResources.spacingM,
                    ),
                    child: Center(
                      child: Text(
                        'Log Out',
                        style: AppFonts.body(color: AppColors.logoutActionText)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppResources.spacingXS,
        bottom: AppResources.spacingS,
      ),
      child: Text(
        title,
        style: AppFonts.bodySmall(color: AppColors.textSecondary)
            .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: tint, size: 22),
    );
  }
}
