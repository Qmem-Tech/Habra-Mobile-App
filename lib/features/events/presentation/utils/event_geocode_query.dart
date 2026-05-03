import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/event_detail.dart';

/// Builds a single-line address suitable for platform [locationFromAddress], when DB lat/lng are missing.
String? geocodeQueryForEvent(EventDetail event) {
  if (event.isOnline) return null;
  final segments = <String>[
    if (event.address.trim().isNotEmpty) event.address.trim(),
    if (event.city.trim().isNotEmpty) event.city.trim(),
    if (event.state.trim().isNotEmpty) event.state.trim(),
    if (event.zipCode != null && event.zipCode!.trim().isNotEmpty)
      event.zipCode!.trim(),
  ];
  if (segments.isNotEmpty) {
    return segments.join(', ');
  }
  final venue = event.venue.trim();
  if (venue.isEmpty || venue.toLowerCase() == 'online') return null;
  return venue;
}

/// Opens Apple/Google Maps with coordinates, or a Google Maps search for the address string.
Future<void> launchEventInExternalMaps(
  BuildContext context,
  EventDetail event, {
  double? latitude,
  double? longitude,
}) async {
  final lat = latitude ?? event.latitude;
  final lng = longitude ?? event.longitude;
  final Uri url;
  if (lat != null && lng != null) {
    if (Platform.isIOS) {
      url = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
    } else {
      url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
    }
  } else {
    final fromQuery = geocodeQueryForEvent(event)?.trim();
    final q = (fromQuery != null && fromQuery.isNotEmpty)
        ? fromQuery
        : event.fullAddress.trim();
    if (q.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location available for directions.')),
        );
      }
      return;
    }
    url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
    );
  }
  try {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }
}
