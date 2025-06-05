// lib/features/home/data/datasources/local/interfaces/category_local_datasource_service.dart
import '../../../models/category/category_model.dart';

abstract class ICategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories({int? userId});
  Stream<List<CategoryModel>> watchCategories({int? userId});
  // Изменено: добавлен параметр userId
  Future<CategoryModel> getCategoryById(String id, {required int userId});
  Future<String> createCategory(CategoryModel category);
  // Сигнатура здесь остается прежней, т.к. userId берется из CategoryModel в реализации
  Future<bool> updateCategory(CategoryModel category);
  // Изменено: добавлен параметр userId
  Future<bool> deleteCategory(String id, {required int userId});
}