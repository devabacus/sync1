// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryEntity _$CategoryEntityFromJson(Map<String, dynamic> json) =>
    _CategoryEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      lastModified: DateTime.parse(json['lastModified'] as String),
      userId: (json['userId'] as num).toInt(),
    );

Map<String, dynamic> _$CategoryEntityToJson(_CategoryEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'lastModified': instance.lastModified.toIso8601String(),
      'userId': instance.userId,
    };
