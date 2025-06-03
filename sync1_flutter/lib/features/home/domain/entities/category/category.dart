
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
abstract class CategoryEntity with _$CategoryEntity {
  const factory CategoryEntity({
    required String id,
required String title,
required DateTime lastModified,
  }) = _CategoryEntity;

  factory CategoryEntity.fromJson(Map<String, dynamic> json) => _$CategoryEntityFromJson(json);
}
