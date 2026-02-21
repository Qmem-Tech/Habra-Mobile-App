import '../models/saved_item_model.dart';

abstract class SavedItemsRemoteDataSource {
  Future<List<SavedItemModel>> getSavedItems({String? filterType});
  Future<void> saveItem({required String itemType, required String referenceId});
  Future<void> removeSavedItem(String savedItemId);
}
