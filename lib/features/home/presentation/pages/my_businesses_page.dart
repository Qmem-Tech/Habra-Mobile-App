import 'package:flutter/material.dart';

import '../../domain/entities/business_presence.dart';
import 'business_locations_page.dart';

/// Lists every listing the owner can switch between (same flow as Home’s location picker).
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
