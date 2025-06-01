import '../datasources/local/interfaces/category_local_datasource_service.dart';
import '../models/extensions/category_model_extension.dart';
import '../../domain/entities/extensions/category_entity_extension.dart';
import '../../domain/entities/category/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  final ICategoryLocalDataSource _localDataSource;

  CategoryRepositoryImpl(this._localDataSource);

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final categoryModels = await _localDataSource.getCategories();
    return categoryModels.toEntities();
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    return _localDataSource.watchCategories().map(
      (models) => models.toEntities(),
    );
  }

  @override
  Future<CategoryEntity> getCategoryById(String id) async {
    final model = await _localDataSource.getCategoryById(id);
    return model.toEntity();
  }

  @override
  Future<String> createCategory(CategoryEntity category) {
    return _localDataSource.createCategory(category.toModel());
  }

  @override
  Future<bool> deleteCategory(String id) async {
    return _localDataSource.deleteCategory(id);
  }

  @override
  Future<bool> updateCategory(CategoryEntity category) async {
    return _localDataSource.updateCategory(category.toModel());
  }

}
