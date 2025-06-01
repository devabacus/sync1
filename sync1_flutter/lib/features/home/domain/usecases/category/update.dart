
import '../../entities/category/category.dart';
import '../../repositories/category_repository.dart';

class UpdateCategoryUseCase {
  final ICategoryRepository _repository;

  UpdateCategoryUseCase(this._repository);

  Future<bool> call(CategoryEntity category) async {
    return _repository.updateCategory(category);
  }
}
