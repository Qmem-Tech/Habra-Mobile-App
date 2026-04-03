import 'package:flutter/material.dart';

import 'update_hours_page.dart';

/// Design name for weekly / daily hours editor.
class OperatingHoursPage extends StatelessWidget {
  const OperatingHoursPage({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    return UpdateHoursPage(
      businessId: businessId,
      appBarTitle: 'Operating hours',
    );
  }
}
