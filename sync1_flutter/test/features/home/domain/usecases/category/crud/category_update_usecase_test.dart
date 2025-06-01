import 'package:sync1/features/home/domain/entities/category/category.dart';
import 'package:sync1/features/home/domain/repositories/category_repository.dart';
import 'package:sync1/features/home/domain/usecases/category/update.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'category_update_usecase_test.mocks.dart';

@GenerateMocks([ICategoryRepository])
void main() {
  late UpdateCategoryUseCase updateCategoryUseCase;
  late MockICategoryRepository mockICategoryRepository;
  const uuid = Uuid();

  setUp(() {
    mockICategoryRepository = MockICategoryRepository();
    updateCategoryUseCase = UpdateCategoryUseCase(mockICategoryRepository);
  });

  test('should call correct update method', () async {
    final testId = uuid.v7();
    final category = CategoryEntity(id: testId, title: 'title 1');
    
    when(
      mockICategoryRepository.updateCategory(category),
    ).thenAnswer((_) async => {});

    await updateCategoryUseCase(category);

    verify(mockICategoryRepository.updateCategory(category)).called(1);
  });
}
