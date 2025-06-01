
import '../../repositories/category_repository.dart';
import '../../entities/category/category.dart';

class GetCategoryByIdUseCase {
  final ICategoryRepository _repository;

  GetCategoryByIdUseCase(this._repository);

  Future<CategoryEntity?> call(String id) {
    return _repository.getCategoryById(id);
  }
}
