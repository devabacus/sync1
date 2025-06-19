// G:\Projects\Flutter\serverpod\sync1\sync1_flutter\lib\features\home\data\datasources\local\sources\category_local_data_source.dart
import '../../../models/extensions/category_model_extension.dart';
import '../../../datasources/local/tables/extensions/category_table_extension.dart';
import '../../../models/category/category_model.dart';
import '../dao/category/category_dao.dart';
import '../interfaces/category_local_datasource_service.dart';

class CategoryLocalDataSource implements ICategoryLocalDataSource {
  final CategoryDao categoryDao;

  CategoryLocalDataSource(this.categoryDao);

  @override
  Future<List<CategoryModel>> getCategories({int? userId}) async {
    final categories = await categoryDao.getCategories(userId: userId);
    return categories.toModels();
  }

  @override
  Stream<List<CategoryModel>> watchCategories({int? userId}) {
    return categoryDao.watchCategories(userId: userId).map((list) => list.toModels());
  }

  @override
  Future<CategoryModel> getCategoryById(String id, {required int userId}) async {
    // Вызываем обновленный метод DAO с userId
    final category = await categoryDao.getCategoryById(id, userId: userId);
    return category.toModel();
  }

  @override
  Future<String> createCategory(CategoryModel category) {
    // category.toCompanion() должен содержать userId, который CategoryDao ожидает
    return categoryDao.createCategory(category.toCompanion());
  }

  @override
  Future<bool> updateCategory(CategoryModel category) {
    // Вызываем обновленный метод DAO, передавая userId из самой модели категории
    // Это предполагает, что CategoryDao.updateCategory был изменен на:
    // Future<bool> updateCategory(CategoryTableCompanion companion, {required int userId})
    return categoryDao.updateCategory(category.toCompanionWithId(), userId: category.userId);
  }   

  @override
  Future<bool> deleteCategory(String id, {required int userId}) async {
    // Вызываем обновленный метод DAO с userId
    return categoryDao.softDeleteCategory(id, userId: userId);
  }
}