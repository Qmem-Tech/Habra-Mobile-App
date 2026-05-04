import 'package:flutter/material.dart';

import '../../../../core/navigation/business_owner_navigation_wrapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';

/// Shown when the selected business is on the Free tier (listing-only): deals/jobs/events UI is blocked.
class DashboardListingTierLocked extends StatelessWidget {
  const DashboardListingTierLocked({
    super.key,
    required this.user,
    required this.sectionLabel,
  });

  final User user;
  /// Short noun phrase, e.g. "deals", "job posts", "events".
  final String sectionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: AppColors.brandPrimary.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 16),
            Text(
              'Free listing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your listing can appear in search with profile details. Posting $sectionLabel requires Standard or Premium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                BusinessOwnerNavigationWrapper.openBusinessOwnerSubscription(
                  context,
                  user,
                );
              },
              child: const Text('View plans'),
            ),
          ],
        ),
      ),
    );
  }
}
