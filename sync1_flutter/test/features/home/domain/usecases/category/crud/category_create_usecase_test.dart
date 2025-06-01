import 'package:sync1/features/home/domain/entities/category/category.dart';
import 'package:sync1/features/home/domain/repositories/category_repository.dart';
import 'package:sync1/features/home/domain/usecases/category/create.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'category_create_usecase_test.mocks.dart';

@GenerateMocks([ICategoryRepository])
void main() {
  late CreateCategoryUseCase createCategoryUseCase;
  late MockICategoryRepository mockICategoryRepository;
  const uuid = Uuid();

  setUp(() {
    mockICategoryRepository = MockICategoryRepository();
    createCategoryUseCase = CreateCategoryUseCase(mockICategoryRepository);
  });

  test('should create new category', () async {
    final testId = uuid.v7();
    final categoryEntity = CategoryEntity(id: testId, title: 'title 1');

    when(
      mockICategoryRepository.createCategory(categoryEntity),
    ).thenAnswer((_) async => testId);

    final result = await createCategoryUseCase(categoryEntity);

    verify(mockICategoryRepository.createCategory(categoryEntity)).called(1);
    expect(result, testId);
  });
}
