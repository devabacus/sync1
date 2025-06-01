
import 'package:drift/drift.dart';
import '../../../../../../../core/database/local/database.dart';
import '../../../domain/entities/category/category.dart';
import '../category/category_model.dart';

extension CategoryModelExtension on CategoryModel {
  CategoryEntity toEntity() => CategoryEntity(id: id, title: title);

  CategoryTableCompanion toCompanion() =>
      CategoryTableCompanion.insert(title: title);

  CategoryTableCompanion toCompanionWithId() =>
      CategoryTableCompanion(id: Value(id), title: Value(title));
}

extension CategoryModelListExtension on List<CategoryModel> {
  List<CategoryEntity> toEntities() =>
      map((model) => model.toEntity()).toList();
}
  