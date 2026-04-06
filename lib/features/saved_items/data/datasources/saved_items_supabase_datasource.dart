import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/saved_item.dart';
import '../models/saved_item_model.dart';
import 'saved_items_remote_datasource.dart';

/// Saved items CRUD via Supabase table `saved_items`.
/// Columns: id, user_id, item_type ('event'|'deal'|'job'), reference_id, created_at. Optional: title, image_url for display.
class SavedItemsSupabaseDataSource implements SavedItemsRemoteDataSource {
  SavedItemsSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  static SavedItemType _itemTypeFromString(String? s) {
    switch (s) {
      case 'deal':
        return SavedItemType.deal;
      case 'job':
        return SavedItemType.job;
      default:
        return SavedItemType.event;
    }
  }

  SavedItemModel _rowToModel(Map<String, dynamic> row) {
    return SavedItemModel(
      id: parseStringRequired(row['id']),
      userId: parseStringRequired(row['user_id']),
      itemType: _itemTypeFromString(row['item_type'] as String?),
      referenceId: parseStringRequired(row['reference_id']),
      savedAt: parseTimestampRequired(row['created_at']),
      title: parseString(row['title']),
      subtitle: parseString(row['subtitle']),
      imageUrl: parseString(row['image_url']),
    );
  }

  @override
  Future<List<SavedItemModel>> getSavedItems({String? filterType}) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return <SavedItemModel>[];

      var query = _client
          .from(SupabaseTables.savedItems)
          .select()
          .eq('user_id', userId);
      if (filterType != null && filterType.isNotEmpty) {
        query = query.eq('item_type', filterType);
      }
      final res = await query.order('created_at', ascending: false);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(_rowToModel).toList();
    });
  }

  @override
  Future<void> saveItem(
      {required String itemType, required String referenceId}) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _client.from(SupabaseTables.savedItems).upsert(
            {
              'user_id': userId,
              'item_type': itemType,
              'reference_id': referenceId,
            },
            onConflict: 'user_id,item_type,reference_id',
          );
    });
  }

  @override
  Future<void> removeSavedItem(String savedItemId) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _client
          .from(SupabaseTables.savedItems)
          .delete()
          .eq('id', savedItemId)
          .eq('user_id', userId);
    });
  }
}
