import 'package:sync1/core/database/local/database.dart';
import 'package:sync1/features/home/data/datasources/local/dao/category/category_dao.dart';
import 'package:sync1/features/home/data/datasources/local/sources/category_local_data_source.dart';
import 'package:sync1/features/home/data/models/category/category_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'category_local_data_source_test.mocks.dart';

@GenerateMocks([CategoryDao])
void main() {
  late MockCategoryDao mockCategoryDao;
  late CategoryLocalDataSource dataSource;
  const uuid = Uuid();

  setUp(() {
    mockCategoryDao = MockCategoryDao();
    dataSource = CategoryLocalDataSource(mockCategoryDao);
  });

  group('CategoryLocalDataSource', () {
    final testId = uuid.v7();
    
    final testCategoryTableData = CategoryTableData(id: testId, title: 'title 1');
   
    final testCategoryModel = CategoryModel(id: testId, title: 'title 1');
   
    final testCategoryModelCompanion = CategoryTableCompanion.insert(title: 'title 1');
   
    final testCategoryModelWithId = CategoryModel(id: testId, title: 'title 1');
   
    final testCategoryTableDataList = [testCategoryTableData];

    test('getCategories должен вернуть list of CategoryModel', () async {
      when(
        mockCategoryDao.getCategories(),
      ).thenAnswer((_) async => testCategoryTableDataList);

      final result = await dataSource.getCategories();

      verify(mockCategoryDao.getCategories()).called(1);
      expect(result.length, equals(1));
      expect(result[0].id, equals(testCategoryModel.id));
      expect(result[0].title, equals(testCategoryModel.title));
    });

    test('getCategoryById должен вернуть CategoryModel', () async {
      when(
        mockCategoryDao.getCategoryById(testId),
      ).thenAnswer((_) async => testCategoryTableData);

      final result = await dataSource.getCategoryById(testId);

      verify(mockCategoryDao.getCategoryById(testId)).called(1);
      expect(result.id, equals(testCategoryModel.id));
      expect(result.title, equals(testCategoryModel.title));
    });

    test(
      'createCategory should call categoryDao.createCategory and return id',
      () async {
        when(
          mockCategoryDao.createCategory(testCategoryModelCompanion),
        ).thenAnswer((_) async => testId);

        final result = await dataSource.createCategory(testCategoryModel);

        verify(mockCategoryDao.createCategory(any)).called(1);
        expect(result, equals(testId));
      },
    );

    test('updateCategory should call categoryDao.updateCategory', () async {
      when(mockCategoryDao.updateCategory(any)).thenAnswer((_) async => {});

      await dataSource.updateCategory(testCategoryModelWithId);

      verify(mockCategoryDao.updateCategory(any)).called(1);
    });

    test('deleteCategory should call categoryDao.deleteCategory', () async {
      when(mockCategoryDao.deleteCategory(testId)).thenAnswer((_) async => {});

      await dataSource.deleteCategory(testId);

      verify(mockCategoryDao.deleteCategory(testId)).called(1);
    });
  });
}

