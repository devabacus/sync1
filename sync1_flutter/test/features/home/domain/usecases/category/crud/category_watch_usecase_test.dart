import 'dart:async';
import 'package:sync1/features/home/domain/entities/category/category.dart';
import 'package:sync1/features/home/domain/repositories/category_repository.dart';
import 'package:sync1/features/home/domain/usecases/category/watch_all.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'category_watch_usecase_test.mocks.dart';

@GenerateMocks([ICategoryRepository])
void main() {
  late WatchCategoriesUseCase watchCategoriesUseCase;
  late MockICategoryRepository mockICategoryRepository;
  const uuid = Uuid();

  setUp(() {
    mockICategoryRepository = MockICategoryRepository();
    watchCategoriesUseCase = WatchCategoriesUseCase(mockICategoryRepository);
  });

  group('watch categories test', () {
    test('should return stream of category list from repository', () {
      final testId1 = uuid.v7();
      final testId2 = uuid.v7();

      final categoriesList = [
        CategoryEntity(id: testId1, title: 'title 1'),
        CategoryEntity(id: testId2, title: 'title 2'),
      ];

      final controller = StreamController<List<CategoryEntity>>();

      when(
        mockICategoryRepository.watchCategories(),
      ).thenAnswer((_) => controller.stream);

      final resultStream = watchCategoriesUseCase();
      verify(mockICategoryRepository.watchCategories()).called(1);
      expectLater(resultStream, emits(categoriesList));
      controller.add(categoriesList);
      addTearDown(() {
        controller.close();
      });
    });

    test('should handle an empty stream from repository', () {
      final controller = StreamController<List<CategoryEntity>>();
      when(
        mockICategoryRepository.watchCategories(),
      ).thenAnswer((_) => controller.stream);

      final resultStream = watchCategoriesUseCase();
      verify(mockICategoryRepository.watchCategories()).called(1);
      expectLater(resultStream, emitsDone);
      controller.close();
    });

    test('should handle stream errors from repository', () {
      final controller = StreamController<List<CategoryEntity>>();
      final exception = Exception('Database error');
      when(
        mockICategoryRepository.watchCategories(),
      ).thenAnswer((_) => controller.stream);

      final resultStream = watchCategoriesUseCase();
      verify(mockICategoryRepository.watchCategories()).called(1);
      expectLater(resultStream, emitsError(isA<Exception>()));
      controller.addError(exception);
      addTearDown(() {
        controller.close();
      });
    });
  });
}
