import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/business_category.dart';
import '../../domain/entities/business_detail.dart';
import '../../domain/entities/business_filters.dart';
import '../../domain/entities/business_list_item.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/my_review.dart';
import '../../domain/entities/review.dart';
import '../models/review_model.dart';
import 'businesses_remote_datasource.dart';

/// Supabase implementation of [BusinessesRemoteDataSource].
/// Requires Supabase to be initialized and schema (businesses, categories, deals, reviews, deal_redemptions) deployed.
class BusinessesSupabaseDataSource implements BusinessesRemoteDataSource {
  BusinessesSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  static BusinessCategory _categoryFromName(String? name) {
    if (name == null || name.isEmpty) return BusinessCategory.other;
    final lower = name.toLowerCase();
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
    return map[lower] ?? BusinessCategory.other;
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
            if (name != null) list.add(_categoryFromName(name));
          }
        }
      }
    }
    if (list.isEmpty) list.add(BusinessCategory.other);
    return list.toList();
  }

  BusinessListItem _rowToBusinessListItem(Map<String, dynamic> row) {
    final id = parseStringRequired(row['id']);
    final name = parseStringRequired(row['name']);
    final logoUrl = parseString(row['logo_url']);
    final imageUrls = parseStringList(row['image_urls']);
    final imageUrl = logoUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');
    final address = parseStringRequired(row['address_street']);
    final city = parseStringRequired(row['address_city']);
    final state = parseStringRequired(row['address_state']);
    final rating = parseDouble(row['rating']) ?? 0.0;
    final reviewCount = parseInt(row['review_count']) ?? 0;
    final priceRange = parseString(row['price_range']);
    final isVerified = parseBool(row['is_verified']);
    final isFeatured = parseBool(row['is_featured']);
    final openingTime = row['opening_time']?.toString();
    final closingTime = row['closing_time']?.toString();
    final categories = _categoriesFromRow(row);

    return BusinessListItem(
      id: id,
      name: name,
      imageUrl: imageUrl.isEmpty ? 'https://placehold.co/400x300?text=Business' : imageUrl,
      categories: categories,
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
      var query = _client
          .from('businesses')
          .select('*, business_categories(categories(name))')
          .eq('approval_status', 'approved')
          .eq('is_active', true);

      if (featuredOnly) query = query.eq('is_featured', true);
      // TODO: Add location filter when ready: query.or('address_city.ilike.%$location%,address_state.ilike.%$location%')
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      final res = await query.order('created_at', ascending: false);
      final list = (res as List).cast<Map<String, dynamic>>();

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
      }

      return items;
    });
  }

  @override
  Future<BusinessDetail> getBusinessDetail(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from('businesses')
          .select('*, business_categories(categories(name))')
          .eq('id', businessId)
          .maybeSingle();
      if (res == null) throw Exception('Business not found');

      final row = Map<String, dynamic>.from(res as Map);
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

      final imageUrls = parseStringList(row['image_urls']);
      final mainImage = parseString(row['logo_url']) ?? (imageUrls.isNotEmpty ? imageUrls.first : '');
      final List<String> allImages = mainImage.isNotEmpty
          ? [mainImage, ...imageUrls.where((u) => u != mainImage)]
          : List<String>.from(imageUrls);
      if (allImages.isEmpty) allImages.add('https://placehold.co/400x300?text=Business');

      return BusinessDetail(
        id: listItem.id,
        name: listItem.name,
        description: parseStringRequired(row['description']),
        imageUrls: allImages,
        categories: listItem.categories,
        address: listItem.address,
        city: listItem.city,
        state: listItem.state,
        zipCode: parseString(row['address_zip']) ?? '',
        latitude: parseDouble(row['latitude']) ?? 0,
        longitude: parseDouble(row['longitude']) ?? 0,
        phoneNumber: parseString(row['phone']),
        website: parseString(row['website']),
        rating: listItem.rating,
        reviewCount: listItem.reviewCount,
        priceRange: listItem.priceRange,
        isVerified: listItem.isVerified,
        isOpen: true,
        closingTime: listItem.closingTime,
        openingTime: listItem.openingTime,
        hours: const [],
        currentDeals: deals,
        reviews: reviews,
        similarBusinesses: const [],
        photos: allImages,
      );
    });
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
          .select('*, businesses!deals_business_id_fkey(id, name, address_city, address_state, logo_url, image_urls)')
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
          b = BusinessListItem(
            id: bid ?? '',
            name: bname,
            imageUrl: parseString(biz['logo_url']) ?? '',
            categories: const [BusinessCategory.other],
            address: '',
            city: parseStringRequired(biz['address_city']),
            state: parseStringRequired(biz['address_state']),
            rating: 0,
            reviewCount: 0,
            isOpen: true,
            isFeatured: false,
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
          .select('*, businesses!deals_business_id_fkey(id, name, address_city, address_state, logo_url, image_urls)')
          .eq('id', dealId)
          .maybeSingle();
      if (res == null) throw Exception('Deal not found');
      final row = Map<String, dynamic>.from(res as Map);
      BusinessListItem? b;
      final biz = row['businesses'];
      if (biz is Map<String, dynamic>) {
        final bid = parseString(biz['id']);
        b = BusinessListItem(
          id: bid ?? '',
          name: parseStringRequired(biz['name']),
          imageUrl: parseString(biz['logo_url']) ?? '',
          categories: const [BusinessCategory.other],
          address: '',
          city: parseStringRequired(biz['address_city']),
          state: parseStringRequired(biz['address_state']),
          rating: 0,
          reviewCount: 0,
          isOpen: true,
          isFeatured: false,
        );
      }
      return _rowToDeal(row, b);
    });
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
  Future<String> redeemDeal(String dealId) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _client.from('deal_redemptions').insert({
        'deal_id': dealId,
        'user_id': userId,
      });

      final deal = await _client.from('deals').select('redemption_count').eq('id', dealId).maybeSingle();
      if (deal is Map<String, dynamic>) {
        final count = (deal['redemption_count'] as num?)?.toInt() ?? 0;
        await _client.from('deals').update({'redemption_count': count + 1}).eq('id', dealId);
      }

      return 'HAB-${DateTime.now().millisecondsSinceEpoch}';
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
}
