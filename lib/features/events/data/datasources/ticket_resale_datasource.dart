import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';

/// Datasource for ticket resale (list ticket for sale).
class TicketResaleDatasource {
  TicketResaleDatasource();

  SupabaseClient get _client => Supabase.instance.client;

  /// List a ticket for resale. Returns the listing id.
  Future<String> listTicketForSale({
    required String ticketId,
    required double askingPrice,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final res = await _client.from(SupabaseTables.ticketListings).insert({
        'ticket_id': ticketId,
        'seller_id': userId,
        'asking_price': askingPrice,
        'status': 'available',
      }).select('id').single();

      return (res as Map)['id'] as String;
    });
  }

  /// Cancel a listing (seller only).
  Future<void> cancelListing(String listingId) async {
    return SupabaseFailureMapper.guard(() async {
      await _client.from(SupabaseTables.ticketListings).update({
        'status': 'cancelled',
      }).eq('id', listingId);
    });
  }
}
