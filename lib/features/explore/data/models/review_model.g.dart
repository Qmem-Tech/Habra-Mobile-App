// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) => ReviewModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  userAvatarUrl: json['userAvatarUrl'] as String?,
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  photoUrls: (json['photoUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  isVerified: json['isVerified'] as bool? ?? false,
);

Map<String, dynamic> _$ReviewModelToJson(ReviewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'userAvatarUrl': instance.userAvatarUrl,
      'rating': instance.rating,
      'comment': instance.comment,
      'createdAt': instance.createdAt.toIso8601String(),
      'photoUrls': instance.photoUrls,
      'isVerified': instance.isVerified,
    };
