import 'package:drift/drift.dart';

import '../../../../../../../core/database/local/interface/i_database_service.dart';
import '../../../../../../../core/database/local/database.dart';
import '../../tables/category_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [CategoryTable])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(IDatabaseService databaseService)
    : super(databaseService.database);


   // Этот геттер нужен для транзакций в репозитории
  AppDatabase get db => attachedDatabase;


  Future<List<CategoryTableData>> getCategories() =>
      select(categoryTable).get();

  Stream<List<CategoryTableData>> watchCategories() =>
      select(categoryTable).watch();

  Future<CategoryTableData> getCategoryById(String id) =>
      (select(categoryTable)..where((t) => t.id.equals(id))).getSingle();

  Future<String> createCategory(CategoryTableCompanion companion) async {
    if (!companion.id.present || companion.id.value.isEmpty) {
      throw ArgumentError('ID категории должен быть предоставлен клиентом');
    }

    if (!companion.title.present || companion.title.value.trim().isEmpty) {
      throw ArgumentError('Название категории не может быть пустым');
    }

    final id = companion.id.value;

    


    try {
      final existingCategory =
          await (select(categoryTable)
            ..where((t) => t.id.equals(id))).getSingleOrNull();

      if (existingCategory != null) {
        throw StateError('Категория с ID $id уже существует');
      }

      await into(categoryTable).insert(companion);
      return id;
    } catch (e) {
      print('Ошибка создания категории: $e');
      rethrow;
    }
  }

  Future<bool> updateCategory(CategoryTableCompanion category) async {
    if (!category.id.present || category.id.value.isEmpty) {
      throw ArgumentError(
        'ID категории должен быть предоставлен для обновления',
      );
    }

    if (!category.title.present || category.title.value.trim().isEmpty) {
      throw ArgumentError('Название категории не может быть пустым');
    }

    try {
      final result = await update(categoryTable).replace(category);
      return result;
    } catch (e) {
      print('Ошибка обновления категории: $e');
      rethrow;
    }
  }

  Future<bool> deleteCategory(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('ID категории не может быть пустым');
    }

    try {
      final result =
          await (delete(categoryTable)..where((t) => t.id.equals(id))).go();
      return result > 0;
    } catch (e) {
      print('Ошибка удаления категории: $e');
      rethrow;
    }
  }

  /// Проверяет существование категории по ID
  Future<bool> categoryExists(String id) async {
    if (id.isEmpty) return false;

    final category =
        await (select(categoryTable)
          ..where((t) => t.id.equals(id))).getSingleOrNull();

    return category != null;
  }

  /// Получает количество категорий
  Future<int> getCategoriesCount() async {
    final countQuery = selectOnly(categoryTable)
      ..addColumns([categoryTable.id.count()]);

    final result = await countQuery.getSingle();
    return result.read(categoryTable.id.count()) ?? 0;
  }

    /// Вставляет список категорий в одной транзакции (батче).
  Future<void> insertCategories(List<CategoryTableCompanion> companions) async {
    await batch((batch) {
      batch.insertAll(categoryTable, companions);
    });
  }

  /// Удаляет все категории из таблицы.
  Future<int> deleteAllCategories() {
    return delete(categoryTable).go();
  }
}
