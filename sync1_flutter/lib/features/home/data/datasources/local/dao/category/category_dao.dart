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

  // Получить все категории пользователя (исключая удаленные)
  Future<List<CategoryTableData>> getCategories({int? userId}) =>
    (select(categoryTable)
      ..where((t) => t.syncStatus.equals(SyncStatus.deleted.name).not())
      ..where((t) => userId != null ? t.userId.equals(userId) : const Constant(true)))
    .get();

  // Следить за изменениями категорий пользователя
  Stream<List<CategoryTableData>> watchCategories({int? userId}) =>
    (select(categoryTable)
      ..where((t) => t.syncStatus.equals(SyncStatus.deleted.name).not())
      ..where((t) => userId != null ? t.userId.equals(userId) : const Constant(true)))
    .watch();

  Future<CategoryTableData> getCategoryById(String id) =>
      (select(categoryTable)..where((t) => t.id.equals(id))).getSingle();

  Future<String> createCategory(CategoryTableCompanion companion) async {
    if (!companion.id.present || companion.id.value.isEmpty) {
      throw ArgumentError('ID категории должен быть предоставлен клиентом');
    }

    if (!companion.title.present || companion.title.value.trim().isEmpty) {
      throw ArgumentError('Название категории не может быть пустым');
    }

    if (!companion.userId.present) {
      throw ArgumentError('userId должен быть указан при создании категории');
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

  Future<bool> softDeleteCategory(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('ID категории не может быть пустым');
    }
    final companion = CategoryTableCompanion(
      syncStatus: Value(SyncStatus.deleted),
      lastModified: Value(DateTime.now()), 
    );
    final updatedRows = await (update(categoryTable)..where((t) => t.id.equals(id))).write(companion);
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

  Future<int> getCategoriesCount({int? userId}) async {
    final countQuery = selectOnly(categoryTable)
      ..addColumns([categoryTable.id.count()])
      ..where(userId != null ? categoryTable.userId.equals(userId) : const Constant(true));

    final result = await countQuery.getSingle();
    return result.read(categoryTable.id.count()) ?? 0;
  }

  Future<void> insertCategories(List<CategoryTableCompanion> companions) async {
    await batch((batch) {
      batch.insertAll(categoryTable, companions);
    });
  }

  Future<int> deleteAllCategories({int? userId}) {
    if (userId != null) {
      return (delete(categoryTable)..where((t) => t.userId.equals(userId))).go();
    } else {
      return delete(categoryTable).go();
    }
  }
}