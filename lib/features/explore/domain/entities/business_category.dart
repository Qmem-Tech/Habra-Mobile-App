import 'package:equatable/equatable.dart';

enum BusinessCategory {
  all,
  food,
  beauty,
  grocery,
  legal,
  coffee,
  spices,
  restaurant,
  cafe,
  barbershop,
  salon,
  import,
  other;

  String get displayName {
    switch (this) {
      case BusinessCategory.all:
        return 'All';
      case BusinessCategory.food:
        return 'Food';
      case BusinessCategory.beauty:
        return 'Beauty';
      case BusinessCategory.grocery:
        return 'Grocery';
      case BusinessCategory.legal:
        return 'Legal';
      case BusinessCategory.coffee:
        return 'Coffee';
      case BusinessCategory.spices:
        return 'Spices';
      case BusinessCategory.restaurant:
        return 'Restaurant';
      case BusinessCategory.cafe:
        return 'Cafe';
      case BusinessCategory.barbershop:
        return 'Barbershop';
      case BusinessCategory.salon:
        return 'Salon';
      case BusinessCategory.import:
        return 'Import';
      case BusinessCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case BusinessCategory.food:
        return 'restaurant';
      case BusinessCategory.beauty:
        return 'content_cut';
      case BusinessCategory.grocery:
        return 'shopping_bag';
      case BusinessCategory.legal:
        return 'gavel';
      case BusinessCategory.coffee:
        return 'local_cafe';
      case BusinessCategory.spices:
        return 'local_florist';
      default:
        return 'store';
    }
  }
}
