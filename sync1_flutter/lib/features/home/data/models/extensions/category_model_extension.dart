import 'package:drift/drift.dart';
import '../../../../../../../core/database/local/database.dart';
import '../../../domain/entities/category/category.dart';
import '../../datasources/local/tables/category_table.dart';
import '../category/category_model.dart';

extension CategoryModelExtension on CategoryModel {
  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        title: title,
        lastModified: lastModified,
        userId: userId,
      );

  CategoryTableCompanion toCompanion() => CategoryTableCompanion(
        id: Value(id),
        title: Value(title),
        lastModified: Value(lastModified), 
        userId: Value(userId),
        syncStatus: Value(SyncStatus.local), // По умолчанию новые записи требуют синхронизации

      );
  
  // Этот метод можно будет удалить, но пока оставим для совместимости
  CategoryTableCompanion toCompanionWithId() => toCompanion();
}

extension CategoryModelListExtension on List<CategoryModel> {
  List<CategoryEntity> toEntities() =>
      map((model) => model.toEntity()).toList();
}