import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/resources/app_resources.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/business_presence.dart';

/// Shows the listing address and opens the device maps app.
class LocationMapPage extends StatelessWidget {
  const LocationMapPage({super.key, required this.business});

  final BusinessPresence business;

  String get _addressLine {
    final parts = <String>[];
    final street = business.locationName?.trim();
    if (street != null && street.isNotEmpty) parts.add(street);
    final city = business.city?.trim();
    final st = business.state?.trim();
    if (city != null && city.isNotEmpty && st != null && st.isNotEmpty) {
      parts.add('$city, $st');
    } else if (city != null && city.isNotEmpty) {
      parts.add(city);
    } else if (st != null && st.isNotEmpty) {
      parts.add(st);
    }
    if (parts.isEmpty) return 'No address on file';
    return parts.join(', ');
  }

  Future<void> _openMaps(BuildContext context) async {
    final query = _addressLine;
    if (query == 'No address on file') return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          'Location & map',
          style: AppFonts.mediumTitle(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppResources.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              business.displayName,
              style: AppFonts.body(color: AppColors.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppResources.spacingM),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    color: AppColors.brandPrimary, size: 28),
                const SizedBox(width: AppResources.spacingS),
                Expanded(
                  child: Text(
                    _addressLine,
                    style: AppFonts.body(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppResources.spacingXL),
            AppButton(
              text: 'Open in maps',
              icon: Icons.map_outlined,
              onPressed:
                  _addressLine == 'No address on file' ? null : () => _openMaps(context),
            ),
            const SizedBox(height: AppResources.spacingM),
            Text(
              'Update the street address under Edit details.',
              style: AppFonts.bodySmall(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
