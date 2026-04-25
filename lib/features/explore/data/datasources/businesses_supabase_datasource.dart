import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/domain/normalized_location.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/business_category.dart';
import '../../domain/entities/business_detail.dart';
import '../../domain/entities/business_filters.dart';
import '../../domain/entities/business_list_item.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_redemption.dart';
import '../../domain/entities/my_review.dart';
import '../../domain/entities/review.dart';
import '../models/review_model.dart';
import 'businesses_remote_datasource.dart';

/// Supabase implementation of [BusinessesRemoteDataSource].
/// Requires Supabase to be initialized and schema (businesses, categories, deals, reviews, deal_redemptions) deployed.
class BusinessesSupabaseDataSource implements BusinessesRemoteDataSource {
  BusinessesSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  static BusinessCategory _categoryFromListing(String? name, String? slug) {
    final map = <String, BusinessCategory>{
      'food': BusinessCategory.food,
      'beauty': BusinessCategory.beauty,
      'grocery': BusinessCategory.grocery,
      'legal': BusinessCategory.legal,
      'coffee': BusinessCategory.coffee,
      'spices': BusinessCategory.spices,
      'restaurant': BusinessCategory.restaurant,
      'cafe': BusinessCategory.cafe,
      'barbershop': BusinessCategory.barbershop,
      'salon': BusinessCategory.salon,
      'import': BusinessCategory.import,
    };
    for (final raw in [slug, name]) {
      if (raw == null || raw.isEmpty) continue;
      final hit = map[raw.toLowerCase().trim()];
      if (hit != null) return hit;
    }
    return BusinessCategory.other;
  }

  List<String> _listingCategoryIdsFromRow(Map<String, dynamic> row) {
    final ids = <String>[];
    final bc = row['business_categories'];
    if (bc is List) {
      for (final e in bc) {
        if (e is Map) {
          final c = e['categories'];
          if (c is Map) {
            final id = parseString(c['id']);
            if (id != null) ids.add(id);
          }
        }
      }
    }
    return ids;
  }

  List<BusinessCategory> _categoriesFromRow(dynamic row) {
    final list = <BusinessCategory>{};
    final bc = row['business_categories'];
    if (bc is List) {
      for (final e in bc) {
        if (e is Map) {
          final c = e['categories'];
          if (c is Map) {
            final name = parseString(c['name']);
            final slug = parseString(c['slug']);
            if (name != null || slug != null) {
              list.add(_categoryFromListing(name, slug));
            }
          }
        }
      }
    }
    if (list.isEmpty) list.add(BusinessCategory.other);
    return list.toList();
  }

  BusinessListItem _rowToBusinessListItem(Map<String, dynamic> row) {
    final location = NormalizedLocation.maybeFromEmbedded(row[SupabaseTables.locations]);
    final id = parseStringRequired(row['id']);
    final name = parseStringRequired(row['name']);
    final logoUrl = parseString(row['logo_url']);
    final imageUrls = parseStringList(row['image_urls']);
    final imageUrl = logoUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');
    final address = location?.addressLine1 ?? parseStringRequired(row['address_street']);
    final city = location?.city ?? parseStringRequired(row['address_city']);
    final state = location?.state ?? parseStringRequired(row['address_state']);
    final rating = parseDouble(row['rating']) ?? 0.0;
    final reviewCount = parseInt(row['review_count']) ?? 0;
    final priceRange = parseString(row['price_range']);
    final isVerified = parseBool(row['is_verified']);
    final isFeatured = parseBool(row['is_featured']);
    final openingTime = row['opening_time']?.toString();
    final closingTime = row['closing_time']?.toString();
    final categories = _categoriesFromRow(row);
    final listingCategoryIds = _listingCategoryIdsFromRow(row);

    return BusinessListItem(
      id: id,
      name: name,
      imageUrl: imageUrl.isEmpty ? 'https://placehold.co/400x300?text=Business' : imageUrl,
      categories: categories,
      listingCategoryIds: listingCategoryIds,
      address: address.isEmpty ? city : address,
      city: city,
      state: state,
      distance: null,
      rating: rating,
      reviewCount: reviewCount,
      priceRange: priceRange,
      isVerified: isVerified,
      isOpen: true,
      closingTime: closingTime,
      openingTime: openingTime,
      isFeatured: isFeatured,
    );
  }

  @override
  Future<List<BusinessListItem>> getBusinesses({
    String? location,
    BusinessFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      final selectWithLocation =
          '*, ${SupabaseTables.locations}(*), business_categories(categories(id, name, slug))';
      const selectLegacy = '*, business_categories(categories(id, name, slug))';

      Future<List<Map<String, dynamic>>> fetch(String select) async {
        var query = _client
            .from('businesses')
            .select(select)
            .eq('approval_status', 'approved')
            .eq('is_active', true);

        if (featuredOnly) query = query.eq('is_featured', true);
        // TODO: Add location filter when ready: query.or('address_city.ilike.%$location%,address_state.ilike.%$location%')
        if (searchQuery != null && searchQuery.isNotEmpty) {
          query = query.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
        }

        final res = await query.order('created_at', ascending: false);
        return (res as List).cast<Map<String, dynamic>>();
      }

      late final List<Map<String, dynamic>> list;
      try {
        list = await fetch(selectWithLocation);
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST200' ||
            e.message.contains('could not find') ||
            e.message.contains('relationship') ||
            e.message.contains('locations')) {
          list = await fetch(selectLegacy);
        } else {
          rethrow;
        }
      }

      var items = list.map(_rowToBusinessListItem).toList();

      if (filters != null) {
        final minRating = filters.minRating;
        if (minRating != null) {
          items = items.where((b) => b.rating >= minRating).toList();
        }
        final priceRange = filters.priceRange;
        if (priceRange != null) {
          items = items.where((b) => b.priceRange == priceRange).toList();
        }
        if (filters.isVerified == true) {
          items = items.where((b) => b.isVerified).toList();
        }
        final category = filters.category;
        if (category != null && category != BusinessCategory.all) {
          items = items.where((b) => b.categories.contains(category)).toList();
        }
        final listingCategoryId = filters.listingCategoryId;
        if (listingCategoryId != null && listingCategoryId.isNotEmpty) {
          items = items
              .where((b) => b.listingCategoryIds.contains(listingCategoryId))
              .toList();
        }
      }

      return items;
    });
  }

  @override
  Future<BusinessDetail> getBusinessDetail(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      Future<dynamic> fetch(String select) => _client
          .from('businesses')
          .select(select)
          .eq('id', businessId)
          .maybeSingle();

      dynamic res;
      try {
        res = await fetch(
          '*, ${SupabaseTables.locations}(*), business_categories(categories(id, name, slug))',
        );
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST200' ||
            e.message.contains('could not find') ||
            e.message.contains('relationship') ||
            e.message.contains('locations')) {
          res = await fetch('*, business_categories(categories(id, name, slug))');
        } else {
          rethrow;
        }
      }
      if (res == null) throw Exception('Business not found');

      final row = Map<String, dynamic>.from(res as Map);
      final location =
          NormalizedLocation.maybeFromEmbedded(row[SupabaseTables.locations]);
      final listItem = _rowToBusinessListItem(row);

      final dealsRes = await _client
          .from('deals')
          .select('*')
          .eq('business_id', businessId)
          .eq('status', 'active');
      final deals = (dealsRes as List).cast<Map<String, dynamic>>().map(_rowToDeal).toList();

      final reviewsRes = await _client
          .from('reviews')
          .select('*, profiles!reviews_user_id_fkey(full_name, avatar_url)')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      final reviews = (reviewsRes as List).cast<Map<String, dynamic>>().map(_rowToReview).toList();

      final gallery = parseStringList(row['image_urls']);
      final backgroundUrl = parseString(row['background_url']);
      final logoUrl = parseString(row['logo_url']);
      final seen = <String>{};
      final allImages = <String>[];
      void addUrl(String? u) {
        final s = u?.trim();
        if (s == null || s.isEmpty || seen.contains(s)) return;
        seen.add(s);
        allImages.add(s);
      }

      addUrl(backgroundUrl);
      for (final u in gallery) {
        addUrl(u);
      }
      addUrl(logoUrl);
      if (allImages.isEmpty) {
        allImages.add('https://placehold.co/400x300?text=Business');
      }

      final listingCategoryIds = _listingCategoryIdsFromRow(row);
      final similar = await _fetchSimilarBusinessListItems(
        excludeBusinessId: businessId,
        categoryIds: listingCategoryIds,
      );

      final isActive = parseBool(row['is_active']);

      return BusinessDetail(
        id: listItem.id,
        name: listItem.name,
        description: parseString(row['description']) ?? '',
        imageUrls: allImages,
        categories: listItem.categories,
        address: listItem.address,
        city: listItem.city,
        state: listItem.state,
        zipCode: location?.postalCode ?? parseString(row['address_zip']) ?? '',
        latitude: location?.latitude ?? parseDouble(row['latitude']) ?? 0,
        longitude: location?.longitude ?? parseDouble(row['longitude']) ?? 0,
        phoneNumber: parseString(row['phone']),
        website: parseString(row['website']),
        rating: listItem.rating,
        reviewCount: listItem.reviewCount,
        priceRange: listItem.priceRange,
        isVerified: listItem.isVerified,
        isOpen: isActive,
        closingTime: listItem.closingTime,
        openingTime: listItem.openingTime,
        hours: const [],
        currentDeals: deals,
        reviews: reviews,
        similarBusinesses: similar,
        photos: List<String>.from(allImages),
      );
    });
  }

  /// Other approved listings sharing a linked category (shuffled, capped).
  Future<List<BusinessListItem>> _fetchSimilarBusinessListItems({
    required String excludeBusinessId,
    required List<String> categoryIds,
  }) async {
    if (categoryIds.isEmpty) return [];
    try {
      final catFilter = categoryIds.length > 5 ? categoryIds.sublist(0, 5) : categoryIds;
      final bcRes = await _client
          .from(SupabaseTables.businessCategories)
          .select('business_id')
          .inFilter('category_id', catFilter);
      final bcRows = (bcRes as List).cast<Map<String, dynamic>>();
      final candidateIds = <String>[];
      final seen = <String>{};
      for (final r in bcRows) {
        final bid = parseString(r['business_id']);
        if (bid == null ||
            bid == excludeBusinessId ||
            seen.contains(bid)) {
          continue;
        }
        seen.add(bid);
        candidateIds.add(bid);
      }
      if (candidateIds.isEmpty) return <BusinessListItem>[];
      candidateIds.shuffle(Random());
      final take = candidateIds.take(16).toList();
      final bizRes = await _client
          .from('businesses')
          .select('*, business_categories(categories(id, name, slug))')
          .inFilter('id', take)
          .eq('approval_status', 'approved')
          .eq('is_active', true);
      final rows = (bizRes as List).cast<Map<String, dynamic>>();
      final byId = {for (final r in rows) parseStringRequired(r['id']): r};
      final ordered = <BusinessListItem>[];
      for (final id in take) {
        final r = byId[id];
        if (r != null) ordered.add(_rowToBusinessListItem(r));
      }
      return ordered.take(8).toList();
    } catch (_) {
      return <BusinessListItem>[];
    }
  }

  Deal _rowToDeal(Map<String, dynamic> row, [BusinessListItem? business]) {
    final id = parseStringRequired(row['id']);
    final businessId = parseStringRequired(row['business_id']);
    final title = parseStringRequired(row['title']);
    final description = parseStringRequired(row['description']);
    final imageUrl = parseString(row['image_url']) ?? '';
    final originalPrice = parseDouble(row['original_price']);
    final discountedPrice = parseDouble(row['discounted_price']);
    final discountPct = parseInt(row['discount_percentage']);
    final validUntil = parseTimestamp(row['valid_until']);

    BusinessListItem biz;
    if (business != null) {
      biz = business;
    } else {
      biz = BusinessListItem(
        id: businessId,
        name: '',
        imageUrl: imageUrl,
        categories: const [BusinessCategory.other],
        listingCategoryIds: const [],
        address: '',
        city: '',
        state: '',
        rating: 0,
        reviewCount: 0,
        isOpen: true,
        isFeatured: false,
      );
    }

    String? discountText;
    if (discountPct != null && discountPct > 0) discountText = '$discountPct% Off';
    if (discountedPrice != null && originalPrice != null && originalPrice > 0) {
      discountText ??= '\$${discountedPrice.toStringAsFixed(2)}';
    }

    return Deal(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl.isEmpty ? 'https://placehold.co/400x300?text=Deal' : imageUrl,
      business: biz,
      type: DealType.other,
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
      discountText: discountText,
      expiresAt: validUntil,
      isRedeemable: true,
    );
  }

  @override
  Future<List<Deal>> getDeals({
    String? location,
    String? category,
    DealType? dealType,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      // Only deals from approved businesses
      final approvedBizRes = await _client
          .from('businesses')
          .select('id')
          .eq('approval_status', 'approved')
          .eq('is_active', true);
      final approvedBizList = approvedBizRes as List;
      if (approvedBizList.isEmpty) return [];
      final approvedIds = approvedBizList.map((e) => (e as Map)['id']).whereType<String>().toList();
      if (approvedIds.isEmpty) return [];

      var query = _client
          .from('deals')
          .select(
            '*, businesses!deals_business_id_fkey(id, name, address_street, address_city, address_state, logo_url, image_urls, phone, rating, review_count, business_categories(categories(id, name, slug)))',
          )
          .eq('status', 'active')
          .gte('valid_until', DateTime.now().toIso8601String())
          .inFilter('business_id', approvedIds);

      // TODO: Add location filter when ready (filter businesses by address_city/address_state)
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final res = await query.order('valid_until', ascending: true);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map((row) {
        BusinessListItem? b;
        final biz = row['businesses'];
        if (biz is Map<String, dynamic>) {
          final bid = parseString(biz['id']);
          final bname = parseStringRequired(biz['name']);
          final logoUrl = parseString(biz['logo_url']);
          final imageUrls = parseStringList(biz['image_urls']);
          final bImage = logoUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');
          b = BusinessListItem(
            id: bid ?? '',
            name: bname,
            imageUrl: bImage,
            categories: _categoriesFromRow(biz),
            listingCategoryIds: _listingCategoryIdsFromRow(biz),
            address: parseStringRequired(biz['address_street']),
            city: parseStringRequired(biz['address_city']),
            state: parseStringRequired(biz['address_state']),
            rating: parseDouble(biz['rating']) ?? 0.0,
            reviewCount: parseInt(biz['review_count']) ?? 0,
            isOpen: true,
            isFeatured: false,
            phone: parseString(biz['phone']),
          );
        }
        return _rowToDeal(row, b);
      }).toList();
    });
  }

  @override
  Future<Deal> getDealDetail(String dealId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from('deals')
          .select(
            '*, businesses!deals_business_id_fkey(id, name, address_street, address_city, address_state, logo_url, image_urls, phone, rating, review_count, business_categories(categories(id, name, slug)))',
          )
          .eq('id', dealId)
          .maybeSingle();
      if (res == null) throw Exception('Deal not found');
      final row = Map<String, dynamic>.from(res as Map);
      final dealStatus = parseString(row['status']);
      final validUntil = parseTimestamp(row['valid_until']);
      if (dealStatus != 'active') {
        throw Exception('Deal not available');
      }
      if (validUntil != null && validUntil.isBefore(DateTime.now())) {
        throw Exception('Deal not available');
      }
      BusinessListItem? b;
      final biz = row['businesses'];
      if (biz is Map<String, dynamic>) {
        final bid = parseString(biz['id']);
        final logoUrl = parseString(biz['logo_url']);
        final imageUrls = parseStringList(biz['image_urls']);
        final bImage = logoUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');
        b = BusinessListItem(
          id: bid ?? '',
          name: parseStringRequired(biz['name']),
          imageUrl: bImage,
          categories: _categoriesFromRow(biz),
          listingCategoryIds: _listingCategoryIdsFromRow(biz),
          address: parseStringRequired(biz['address_street']),
          city: parseStringRequired(biz['address_city']),
          state: parseStringRequired(biz['address_state']),
          rating: parseDouble(biz['rating']) ?? 0.0,
          reviewCount: parseInt(biz['review_count']) ?? 0,
          isOpen: true,
          isFeatured: false,
          phone: parseString(biz['phone']),
        );
      }
      return _rowToDeal(row, b);
    });
  }

  String _generateRedemptionCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    final buf = StringBuffer('HAB-');
    for (var i = 0; i < 8; i++) {
      buf.write(chars[r.nextInt(chars.length)]);
    }
    return buf.toString();
  }

  Review _rowToReview(Map<String, dynamic> row) {
    final id = parseStringRequired(row['id']);
    final userId = parseStringRequired(row['user_id']);
    final rating = parseInt(row['rating']) ?? 5;
    final comment = parseStringRequired(row['comment']);
    final createdAt = parseTimestampRequired(row['created_at']);
    final photoUrls = parseStringList(row['image_urls']);
    String userName = 'User';
    String? userAvatarUrl;
    final p = row['profiles'];
    if (p is Map<String, dynamic>) {
      userName = parseStringRequired(p['full_name'], 'User');
      userAvatarUrl = parseString(p['avatar_url']);
    }

    return ReviewModel(
      id: id,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
      photoUrls: photoUrls.isNotEmpty ? photoUrls : null,
      isVerified: false,
    );
  }

  @override
  Future<List<Review>> getBusinessReviews(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from('reviews')
          .select('*, profiles!reviews_user_id_fkey(full_name, avatar_url)')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(_rowToReview).toList();
    });
  }

  @override
  Future<Review> writeReview({
    required String businessId,
    required int rating,
    required String comment,
    List<String>? photoUrls,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final insert = {
        'business_id': businessId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
        if (photoUrls != null && photoUrls.isNotEmpty) 'image_urls': photoUrls,
      };
      await _client.from('reviews').insert(insert);

      final res = await _client
          .from('reviews')
          .select('*, profiles!reviews_user_id_fkey(full_name, avatar_url)')
          .eq('business_id', businessId)
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (res != null) return _rowToReview(Map<String, dynamic>.from(res as Map));

      return ReviewModel(
        id: '',
        userId: userId,
        userName: 'You',
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        photoUrls: photoUrls,
        isVerified: false,
      );
    });
  }

  @override
  Future<DealRedemption> redeemDeal(String dealId) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      for (var attempt = 0; attempt < 6; attempt++) {
        final code = _generateRedemptionCode();
        try {
          final res = await _client
              .from('deal_redemptions')
              .insert({
                'deal_id': dealId,
                'user_id': userId,
                'redemption_code': code,
              })
              .select('id, redemption_code')
              .single();
          final id = parseStringRequired(res['id']);
          final stored = parseStringRequired(res['redemption_code'], code);
          return DealRedemption(id: id, code: stored);
        } catch (e) {
          final msg = e.toString().toLowerCase();
          if (msg.contains('deal_redemptions_one_per_user') ||
              (msg.contains('duplicate key') && msg.contains('deal_id'))) {
            throw Exception('You already redeemed this deal.');
          }
          if (msg.contains('redemption_code') && msg.contains('duplicate')) {
            continue;
          }
          if (msg.contains('redemption_code') &&
              (msg.contains('null') || msg.contains('column'))) {
            throw Exception(
              'Redemption is not fully set up yet. Ask your admin to run the latest deal_redemptions migration in Supabase.',
            );
          }
          rethrow;
        }
      }
      throw Exception('Could not assign a redemption code. Please try again.');
    });
  }

  @override
  Future<List<MyReview>> getMyReviews() async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return <MyReview>[];

      final res = await _client
          .from('reviews')
          .select('*, businesses!reviews_business_id_fkey(id, name, logo_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(_rowToMyReview).toList();
    });
  }

  MyReview _rowToMyReview(Map<String, dynamic> row) {
    final id = parseStringRequired(row['id']);
    final businessId = parseStringRequired(row['business_id']);
    final rating = parseInt(row['rating']) ?? 5;
    final comment = parseStringRequired(row['comment']);
    final createdAt = parseTimestampRequired(row['created_at']);
    String businessName = 'Business';
    String? businessImageUrl;
    final biz = row['businesses'];
    if (biz is Map<String, dynamic>) {
      businessName = parseStringRequired(biz['name'], 'Business');
      businessImageUrl = parseString(biz['logo_url']);
    }
    return MyReview(
      id: id,
      businessId: businessId,
      businessName: businessName,
      businessImageUrl: businessImageUrl,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
    );
  }

  @override
  Future<MyReview> updateReview(String reviewId, {int? rating, String? comment}) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final Map<String, dynamic> payload = {};
      if (rating != null) payload['rating'] = rating;
      if (comment != null) payload['comment'] = comment;
      if (payload.isEmpty) {
        final res = await _client
            .from('reviews')
            .select('*, businesses!reviews_business_id_fkey(id, name, logo_url)')
            .eq('id', reviewId)
            .eq('user_id', userId)
            .maybeSingle();
        if (res == null) throw Exception('Review not found');
        return _rowToMyReview(Map<String, dynamic>.from(res as Map));
      }

      await _client
          .from('reviews')
          .update(payload)
          .eq('id', reviewId)
          .eq('user_id', userId);

      final res = await _client
          .from('reviews')
          .select('*, businesses!reviews_business_id_fkey(id, name, logo_url)')
          .eq('id', reviewId)
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) throw Exception('Review not found');
      return _rowToMyReview(Map<String, dynamic>.from(res as Map));
    });
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');
      await _client
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', userId);
    });
  }

  @override
  Future<void> recordBusinessListingView(String businessId) async {
    try {
      final uid = _client.auth.currentUser?.id;
      await _client.from(SupabaseTables.businessListingViews).insert({
        'business_id': businessId,
        if (uid != null) 'viewer_user_id': uid,
      });
    } catch (_) {
      // Missing migration, RLS, or offline — do not block the detail screen.
    }
  }
}
