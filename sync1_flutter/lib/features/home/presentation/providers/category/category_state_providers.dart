
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/providers/category/category_data_providers.dart';
import '../../../domain/entities/category/category.dart';
import '../../../domain/providers/category/category_usecase_providers.dart';

part 'category_state_providers.g.dart';

@riverpod
class Categories extends _$Categories {
  @override
  Future<List<CategoryEntity>> build() {
    return ref.read(getCategoriesUseCaseProvider)();
  }

  Future<void> addCategory(CategoryEntity category) async {
    state = await AsyncValue.guard(() async {
      await ref.read(createCategoryUseCaseProvider)(category);
      return ref.read(getCategoriesUseCaseProvider)();
    });
  }

  Future<void> updateCategory(CategoryEntity category) async {
    state = await AsyncValue.guard(() async {
      await ref.read(updateCategoryUseCaseProvider)(category);
      return ref.read(getCategoriesUseCaseProvider)();
    });
  }

  Future<void> deleteCategory(String id) async {
    state = await AsyncValue.guard(() async {
      await ref.read(deleteCategoryUseCaseProvider)(id);
      return ref.read(getCategoriesUseCaseProvider)();
    });
  }
  // lib/features/home/presentation/providers/category/category_state_providers.dart

  Future<void> syncCategories() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(categoryRepositoryProvider).syncWithServer();
      return ref.read(getCategoriesUseCaseProvider)();
    });
  }
}
  