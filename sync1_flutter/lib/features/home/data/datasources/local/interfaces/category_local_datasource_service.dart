import '../../../models/category/category_model.dart';

abstract class ICategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories({int? userId});
  Stream<List<CategoryModel>> watchCategories({int? userId});
  Future<CategoryModel> getCategoryById(String id);
  Future<String> createCategory(CategoryModel category);
  Future<bool> updateCategory(CategoryModel category);
  Future<bool> deleteCategory(String id);
}