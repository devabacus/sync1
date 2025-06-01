
import '../../repositories/category_repository.dart';

class DeleteCategoryUseCase {
  final ICategoryRepository _repository;

  DeleteCategoryUseCase(this._repository);

  Future<bool> call(String id) async {
    return _repository.deleteCategory(id);
  }
}
