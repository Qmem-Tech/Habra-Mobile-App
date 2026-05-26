import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/listing_category.dart';
import 'categories_remote_datasource.dart';

class CategoriesSupabaseDataSource implements CategoriesRemoteDataSource {
  CategoriesSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<ListingCategory>> getActiveListingCategories() async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.categories)
          .select('id, name, slug, icon_key, sort_order')
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('name', ascending: true);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows
          .map(
            (row) => ListingCategory(
              id: parseStringRequired(row['id']),
              name: parseStringRequired(row['name']),
              slug: parseString(row['slug']),
              iconKey: parseString(row['icon_key']),
              sortOrder: parseInt(row['sort_order']),
            ),
          )
          .toList();
    });
  }
}
