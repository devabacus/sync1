
import 'dart:async';
import '../../repositories/category_repository.dart';
import '../../entities/category/category.dart';

class WatchCategoriesUseCase {
  final ICategoryRepository _repository;

  WatchCategoriesUseCase(this._repository);

  Stream<List<CategoryEntity>> call() {
    return _repository.watchCategories();
  }
}
