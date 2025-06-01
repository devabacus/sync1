import 'package:drift/drift.dart';
import '../../../../../../../core/database/local/database.dart';
import '../../../domain/entities/category/category.dart';
import '../category/category_model.dart';

extension CategoryModelExtension on CategoryModel {
  CategoryEntity toEntity() => CategoryEntity(id: id, title: title);

  /// Создает CategoryTableCompanion с ID для операций создания
  /// Теперь всегда включает ID, так как он генерируется на клиенте
  CategoryTableCompanion toCompanion() => CategoryTableCompanion(
    id: Value(id),
    title: Value(title),
  );

  /// Создает CategoryTableCompanion с ID для операций обновления
  /// Метод оставлен для совместимости, но теперь идентичен toCompanion()
  CategoryTableCompanion toCompanionWithId() => CategoryTableCompanion(
    id: Value(id),
    title: Value(title),
  );

  /// Создает CategoryTableCompanion только с title (без ID)
  /// Полезно в редких случаях, когда ID не нужен
  CategoryTableCompanion toCompanionWithoutId() => CategoryTableCompanion.insert(
    title: title,
  );
}

extension CategoryModelListExtension on List<CategoryModel> {
  List<CategoryEntity> toEntities() =>
      map((model) => model.toEntity()).toList();
}