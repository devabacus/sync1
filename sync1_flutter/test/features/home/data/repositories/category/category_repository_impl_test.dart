import 'package:sync1/features/home/data/datasources/local/interfaces/category_local_datasource_service.dart';
import 'package:sync1/features/home/data/models/category/category_model.dart';
import 'package:sync1/features/home/data/repositories/category_repository_impl.dart';
import 'package:sync1/features/home/domain/entities/category/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'category_repository_impl_test.mocks.dart';

@GenerateMocks([ICategoryLocalDataSource])
void main() {
  late MockICategoryLocalDataSource mockCategoryLocalDataSource;
  late CategoryRepositoryImpl categoryRepositoryImpl;
  const uuid = Uuid();

  setUp(() {
    mockCategoryLocalDataSource = MockICategoryLocalDataSource();
    categoryRepositoryImpl = CategoryRepositoryImpl(
      mockCategoryLocalDataSource,
    );
  });

  group('categoryRepositoryImpl', () {
    final testId = uuid.v7();

    final testCategoryModel = CategoryModel(id: testId, title: 'title 1');
    final testCategoryModelList = [CategoryModel(id: testId, title: 'title 1')];
    final testCategoryEntity = CategoryEntity(id: testId, title: 'title 1');

    test('getCategories', () async {
      when(
        mockCategoryLocalDataSource.getCategories(),
      ).thenAnswer((_) async => testCategoryModelList);

      final categories = await categoryRepositoryImpl.getCategories();

      verify(mockCategoryLocalDataSource.getCategories()).called(1);
      expect(categories.length, 1);
      expect(categories[0].id, equals(testCategoryModel.id));
      expect(categories[0].title, equals(testCategoryModel.title));
    });

    test('getCategoryById', () async {
      when(
        mockCategoryLocalDataSource.getCategoryById(testId),
      ).thenAnswer((_) async => testCategoryModel);

      final result = await categoryRepositoryImpl.getCategoryById(testId);

      verify(mockCategoryLocalDataSource.getCategoryById(testId)).called(1);

      expect(result.id, equals(testCategoryModel.id));
      expect(result.title, equals(testCategoryModel.title));
    });
    test('createCategory', () async {
      when(
        mockCategoryLocalDataSource.createCategory(any),
      ).thenAnswer((_) async => testId);

      final result = await categoryRepositoryImpl.createCategory(
        testCategoryEntity,
      );

      verify(mockCategoryLocalDataSource.createCategory(any)).called(1);
      expect(result, equals(testId));
    });

    test('updateCategory', () async {
      when(
        mockCategoryLocalDataSource.updateCategory(any),
      ).thenAnswer((_) async => {});

      await categoryRepositoryImpl.updateCategory(testCategoryEntity);

      verify(mockCategoryLocalDataSource.updateCategory(any)).called(1);
    });

    test('deleteCategory', () async {
      when(
        mockCategoryLocalDataSource.deleteCategory(testId),
      ).thenAnswer((_) async => {});

      await categoryRepositoryImpl.deleteCategory(testId);

      verify(mockCategoryLocalDataSource.deleteCategory(testId)).called(1);
    });
  });
}


