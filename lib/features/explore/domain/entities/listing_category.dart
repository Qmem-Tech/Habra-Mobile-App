import 'package:equatable/equatable.dart';

/// Row from `categories` (Super Admin listing categories).
class ListingCategory extends Equatable {
  final String id;
  final String name;
  final String? slug;
  final String? iconKey;
  final int? sortOrder;

  const ListingCategory({
    required this.id,
    required this.name,
    this.slug,
    this.iconKey,
    this.sortOrder,
  });

  @override
  List<Object?> get props => [id, name, slug, iconKey, sortOrder];
}
