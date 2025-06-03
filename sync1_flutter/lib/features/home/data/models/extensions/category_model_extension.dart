import 'package:drift/drift.dart';
import '../../../../../../../core/database/local/database.dart';
import '../../../domain/entities/category/category.dart';
import '../category/category_model.dart';

extension CategoryModelExtension on CategoryModel {
  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        title: title,
        lastModified: lastModified, // <-- Добавили
      );

  CategoryTableCompanion toCompanion() => CategoryTableCompanion(
        id: Value(id),
        title: Value(title),
        lastModified: Value(lastModified), // <-- Добавили
        // syncStatus и deleted будут установлены в репозитории
      );
  
  // Этот метод можно будет удалить, но пока оставим для совместимости
  CategoryTableCompanion toCompanionWithId() => toCompanion();
}

extension CategoryModelListExtension on List<CategoryModel> {
  List<CategoryEntity> toEntities() =>
      map((model) => model.toEntity()).toList();
}