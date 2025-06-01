
import '../../repositories/category_repository.dart';
import '../../entities/category/category.dart';

class GetCategoriesUseCase {
  final ICategoryRepository _repository;

  GetCategoriesUseCase(this._repository);

  Future<List<CategoryEntity>> call() {
    return _repository.getCategories();
  }
}
