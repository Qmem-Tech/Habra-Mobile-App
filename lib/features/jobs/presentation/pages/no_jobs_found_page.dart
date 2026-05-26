import 'package:flutter/material.dart';
import '../../../../core/resources/app_assets.dart';
import '../widgets/empty_state_widget.dart';

class NoJobsFoundPage extends StatelessWidget {
  final String? location;
  final VoidCallback? onLocationChange;

  const NoJobsFoundPage({
    super.key,
    this.location,
    this.onLocationChange,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      illustrationPath: AppAssets.noJobsFound,
      title: 'No jobs found',
      message:
          'We couldn\'t find any listings matching your current place. Try changing your locations',
      buttonLabel: 'Change Location',
      onButtonTap: onLocationChange ?? () {
        // TODO: Show location picker
      },
    );
  }
}
