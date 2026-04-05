import 'package:flutter/material.dart';

import '../../domain/entities/business_presence.dart';
import 'business_locations_page.dart';

/// Full My Businesses card UI: used from profile, home/dashboard/boosts app bar selector,
/// drawer flows (edit / photos), and setup when choosing a listing.
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
    );
  }
}
