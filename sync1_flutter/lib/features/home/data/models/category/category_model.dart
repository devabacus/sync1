import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

@freezed
abstract class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    required String id,
    required String title,
    required DateTime lastModified, // <-- Добавляем это поле
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);
}