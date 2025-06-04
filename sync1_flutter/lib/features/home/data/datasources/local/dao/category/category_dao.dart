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

  AppDatabase get db => attachedDatabase;

  // ИЗМЕНЕНИЕ: Исправлен синтаксис where-условия
  Future<List<CategoryTableData>> getCategories() =>
    (select(categoryTable)..where((t) => t.syncStatus.equals(SyncStatus.deleted.name).not())).get();

  // ИЗМЕНЕНИЕ: Исправлен синтаксис where-условия
  Stream<List<CategoryTableData>> watchCategories() =>
    (select(categoryTable)..where((t) => t.syncStatus.equals(SyncStatus.deleted.name).not())).watch();

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

   // ИЗМЕНЕНИЕ: Исправлен метод softDeleteCategory
  Future<bool> softDeleteCategory(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('ID категории не может быть пустым');
    }
    final companion = CategoryTableCompanion(
      // Мы не передаем id в companion для write, так как он будет в where
      syncStatus: Value(SyncStatus.deleted),
      lastModified: Value(DateTime.now()), 
    );
    // Используем (update()..where()).write() для частичного обновления
    final updatedRows = await (update(categoryTable)..where((t) => t.id.equals(id))).write(companion);
    // write возвращает количество измененных строк
    return updatedRows > 0;
  }


  Future<int> physicallyDeleteCategory(String id) async {
    return (delete(categoryTable)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> categoryExists(String id) async {
    if (id.isEmpty) return false;

    final category =
        await (select(categoryTable)
          ..where((t) => t.id.equals(id))).getSingleOrNull();

    return category != null;
  }

  Future<int> getCategoriesCount() async {
    final countQuery = selectOnly(categoryTable)
      ..addColumns([categoryTable.id.count()]);

    final result = await countQuery.getSingle();
    return result.read(categoryTable.id.count()) ?? 0;
  }

    Future<void> insertCategories(List<CategoryTableCompanion> companions) async {
    await batch((batch) {
      batch.insertAll(categoryTable, companions);
    });
  }

  Future<int> deleteAllCategories() {
    return delete(categoryTable).go();
  }
}