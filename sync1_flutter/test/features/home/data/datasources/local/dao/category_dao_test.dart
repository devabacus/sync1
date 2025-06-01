
    import 'package:sync1/core/database/local/database.dart';
import 'package:sync1/features/home/data/datasources/local/dao/category/category_dao.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import '../../../../../../core/database/local/test_database_service.dart';

void main() {
  late TestDatabaseService databaseService;
  late CategoryDao categoryDao;
  const uuid = Uuid();

  setUp(() {
    databaseService = TestDatabaseService();
    categoryDao = CategoryDao(databaseService);
  });

  tearDown(() async {
    await databaseService.close();
  });

  group('CategoryDao', () {
    test('should create a new category', () async {
      final testId = uuid.v7();
      final categoryCompanion = CategoryTableCompanion.insert(
        id: Value(testId),
        title: 'title 1'
      );

      final createdCategoryId = await categoryDao.createCategory(
        categoryCompanion,
      );
      expect(createdCategoryId, testId);

      final categoryFromDb = await categoryDao.getCategoryById(testId);
      expect(categoryFromDb, isNotNull);
      expect(categoryFromDb.id, testId);
      expect(categoryFromDb.title, 'title 1');
    });

    test('should get all categories', () async {
      final id1 = uuid.v7();
      final id2 = uuid.v7();

      await categoryDao.createCategory(
        CategoryTableCompanion.insert(id: Value(id1), title: 'title 1'),
      );
      await categoryDao.createCategory(
        CategoryTableCompanion.insert(id: Value(id2), title: 'title 2'),
      );

      final categories = await categoryDao.getCategories();

      expect(categories.length, 2);
      expect(
        categories.any((item) => item.id == id1 && item.title == 'title 1'),
        isTrue,
      );
      expect(
        categories.any((item) => item.id == id2 && item.title == 'title 2'),
        isTrue,
      );
    });

    test('should get category by id', () async {
      final testId = uuid.v7();
      await categoryDao.createCategory(
        CategoryTableCompanion.insert(id: Value(testId), title: 'title 1'),
      );

      final category = await categoryDao.getCategoryById(testId);

      expect(category, isNotNull);
      expect(category.id, testId);
      expect(category.title, 'title 1');
    });

    test('should update category', () async {
      final testId = uuid.v7();
      await categoryDao.createCategory(
        CategoryTableCompanion.insert(id: Value(testId), title: 'title 1'),
      );

      await categoryDao.updateCategory(
        CategoryTableCompanion(
          id: Value(testId), title: Value('title 2')
        ),
      );

      final updatedCategory = await categoryDao.getCategoryById(testId);
      expect(updatedCategory, isNotNull);
      expect(updatedCategory.title, 'title 2');
    });

    test('should delete category', () async {
      final testId = uuid.v7();
      await categoryDao.createCategory(
        CategoryTableCompanion.insert(
          id: Value(testId),
          title: 'title 1'
        ),
      );

      await categoryDao.deleteCategory(testId);

      expect(
        () => categoryDao.getCategoryById(testId),
        throwsA(isA<StateError>()),
      );
    });
  });
}

  
