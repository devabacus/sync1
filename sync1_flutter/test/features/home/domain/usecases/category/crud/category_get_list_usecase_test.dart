import 'package:sync1/features/home/domain/entities/category/category.dart';
import 'package:sync1/features/home/domain/repositories/category_repository.dart';
import 'package:sync1/features/home/domain/usecases/category/get_all.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'category_get_list_usecase_test.mocks.dart';

@GenerateMocks([ICategoryRepository])
void main() {
  late GetCategoriesUseCase getCategoriesUseCase;
  late MockICategoryRepository mockICategoryRepository;
  const uuid = Uuid();

  setUp(() {
    mockICategoryRepository = MockICategoryRepository();
    getCategoriesUseCase = GetCategoriesUseCase(mockICategoryRepository);
  });

  test('should return list of items from repository', () async {
    final testId1 = uuid.v7();
    final testId2 = uuid.v7();

    final categories = [
      CategoryEntity(id: testId1, title: 'title 1'),
      CategoryEntity(id: testId2, title: 'title 2'),
    ];
    
    when(
      mockICategoryRepository.getCategories(),
    ).thenAnswer((_) async => categories);

    final result = await getCategoriesUseCase();

    verify(mockICategoryRepository.getCategories()).called(1);
    expect(result, categories);
    expect(result.length, 2);
  });
}
