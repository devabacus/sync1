import 'package:sync1/features/home/domain/repositories/category_repository.dart';
import 'package:sync1/features/home/domain/usecases/category/delete.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'category_delete_usecase_test.mocks.dart';

@GenerateMocks([ICategoryRepository])
void main() {
  late DeleteCategoryUseCase deleteCategoryUseCase;
  late MockICategoryRepository mockICategoryRepository;
  const uuid = Uuid();

  setUp(() {
    mockICategoryRepository = MockICategoryRepository();
    deleteCategoryUseCase = DeleteCategoryUseCase(mockICategoryRepository);
  });

  test('should call delete with correct id', () async {
    final testId = uuid.v7();
    
    when(
      mockICategoryRepository.deleteCategory(testId),
    ).thenAnswer((_) async => {});

    await deleteCategoryUseCase(testId);

    verify(mockICategoryRepository.deleteCategory(testId)).called(1);
  });
}

