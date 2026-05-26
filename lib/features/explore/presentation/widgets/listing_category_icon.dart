import 'package:flutter/material.dart';

IconData listingCategoryIcon(String? iconKey) {
  final key = (iconKey ?? '').trim().toLowerCase();
  switch (key) {
    case 'restaurant':
    case 'food':
      return Icons.restaurant;
    case 'content_cut':
    case 'beauty':
    case 'salon':
    case 'barbershop':
      return Icons.content_cut;
    case 'shopping_bag':
    case 'grocery':
    case 'retail':
      return Icons.shopping_bag;
    case 'gavel':
    case 'legal':
      return Icons.gavel;
    case 'local_cafe':
    case 'coffee':
    case 'cafe':
      return Icons.local_cafe;
    case 'local_florist':
    case 'spices':
      return Icons.local_florist;
    case 'local_hospital':
    case 'health':
      return Icons.local_hospital;
    case 'school':
    case 'education':
      return Icons.school;
    case 'directions_car':
    case 'automotive':
      return Icons.directions_car;
    case 'home_work':
    case 'real_estate':
      return Icons.home_work;
    default:
      return Icons.store;
  }
}
