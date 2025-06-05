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

  // Получить категорию по ID с проверкой принадлежности пользователю
  Future<CategoryTableData> getCategoryById(String id, {required int userId}) =>
      (select(categoryTable)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .getSingle();

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

 // Предлагаемое изменение в CategoryDao
Future<bool> updateCategory(CategoryTableCompanion companion, {required int userId}) async {
    if (!companion.id.present || companion.id.value.isEmpty) {
        throw ArgumentError('ID категории должен быть предоставлен для обновления');
    }
    if (!companion.title.present || companion.title.value.trim().isEmpty) {
        throw ArgumentError('Название категории не может быть пустым');
    }
    // Дополнительно можно проверить, что companion.userId (если присутствует) совпадает с userId параметром,
    // или просто не включать userId в companion, если он не меняется.

    final idToUpdate = companion.id.value;
    final updatedRows = await (update(categoryTable)
      ..where((t) => t.id.equals(idToUpdate) & t.userId.equals(userId))) // Обновляем, только если ID и userId совпадают
      .write(companion); // companion содержит обновляемые поля
    return updatedRows > 0;
}

  // Мягкое удаление с проверкой принадлежности пользователю
  Future<bool> softDeleteCategory(String id, {required int userId}) async {
    if (id.isEmpty) {
      throw ArgumentError('ID категории не может быть пустым');
    }
    
    final companion = CategoryTableCompanion(
      syncStatus: Value(SyncStatus.deleted),
      lastModified: Value(DateTime.now()), 
    );
    
    final updatedRows = await (update(categoryTable)
      ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .write(companion);
    
    return updatedRows > 0;
  }

  // Физическое удаление с проверкой принадлежности пользователю
  Future<int> physicallyDeleteCategory(String id, {required int userId}) async {
    return (delete(categoryTable)
      ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .go();
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