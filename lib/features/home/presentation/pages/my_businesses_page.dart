import 'package:flutter/material.dart';

import '../../domain/entities/business_presence.dart';
import 'business_locations_page.dart';

/// Owner listing picker: **My Locations** branch-style cards + Add New Location.
/// Used from profile, home pill, drawer, and other flows that choose a listing.
class MyBusinessesPage extends StatelessWidget {
  const MyBusinessesPage({
    super.key,
    required this.presences,
    this.currentPresenceId,
  });

  final List<BusinessPresence> presences;
  final String? currentPresenceId;

  @override
  Widget build(BuildContext context) {
    return BusinessLocationsPage(
      presences: presences,
      currentPresenceId: currentPresenceId,
      overrideAppBarTitle: 'My Locations',
      flatBranchCardLayout: true,
    );
  }
}
