import 'package:flutter/material.dart';

import '../../domain/entities/business_presence.dart';
import 'business_locations_page.dart';

/// Owner listing picker: **My Businesses** — one card per brand (grouped by
/// [BusinessPresence.businessGroupName] / root name), with **View Locations**
/// to pick a branch. Used from profile, home pill, drawer, and other flows.
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
      overrideAppBarTitle: 'My Businesses',
      flatBranchCardLayout: false,
    );
  }
}
