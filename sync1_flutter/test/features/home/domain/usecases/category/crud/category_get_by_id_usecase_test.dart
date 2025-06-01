import 'package:sync1/features/home/domain/entities/category/category.dart';
import 'package:sync1/features/home/domain/repositories/category_repository.dart';
import 'package:sync1/features/home/domain/usecases/category/get_by_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'category_get_by_id_usecase_test.mocks.dart';

@GenerateMocks([ICategoryRepository])
void main() {
  late GetCategoryByIdUseCase getCategoryByIdUseCase;
  late MockICategoryRepository mockICategoryRepository;
  const uuid = Uuid();

  setUp(() {
    mockICategoryRepository = MockICategoryRepository();
    getCategoryByIdUseCase = GetCategoryByIdUseCase(mockICategoryRepository);
  });

  test('should return correct item by id', () async {
    final testId = uuid.v7();
    final category = CategoryEntity(id: testId, title: 'title 1');
    
    when(
      mockICategoryRepository.getCategoryById(testId),
    ).thenAnswer((_) async => category);

    final result = await getCategoryByIdUseCase(testId);

    verify(mockICategoryRepository.getCategoryById(testId)).called(1);
    expect(result, category);
    expect(result?.id, testId);
    expect(result?.title, 'title 1');
  });

  test('shoul throw exception', () async {
    const wrongId = '999';
    
    when(
      mockICategoryRepository.getCategoryById(wrongId),
    ).thenThrow(StateError('Category not found'));

    expect(
      () => getCategoryByIdUseCase(wrongId),
      throwsA(isA<StateError>()),
    );
    verify(mockICategoryRepository.getCategoryById(wrongId)).called(1);
  });
}
