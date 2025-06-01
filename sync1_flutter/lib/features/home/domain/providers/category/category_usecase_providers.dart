import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../usecases/category/create.dart';
import '../../usecases/category/delete.dart';
import '../../usecases/category/get_by_id.dart';
import '../../usecases/category/update.dart';
import '../../usecases/category/get_all.dart';
import '../../usecases/category/watch_all.dart';

import '../../../data/providers/category/category_data_providers.dart';

part 'category_usecase_providers.g.dart';

@riverpod
GetCategoriesUseCase getCategoriesUseCase(Ref ref) {
  final repository = ref.read(categoryRepositoryProvider);
  return GetCategoriesUseCase(repository);
}

@riverpod
WatchCategoriesUseCase watchCategoriesUseCase(Ref ref) {
  final repository = ref.read(categoryRepositoryProvider);
  return WatchCategoriesUseCase(repository);
}

@riverpod
CreateCategoryUseCase createCategoryUseCase(Ref ref) {
  final repository = ref.read(categoryRepositoryProvider);
  return CreateCategoryUseCase(repository);
}

@riverpod
DeleteCategoryUseCase deleteCategoryUseCase(Ref ref) {
  final repository = ref.read(categoryRepositoryProvider);
  return DeleteCategoryUseCase(repository);
}

@riverpod
UpdateCategoryUseCase updateCategoryUseCase(Ref ref) {
  final repository = ref.read(categoryRepositoryProvider);
  return UpdateCategoryUseCase(repository);
}

@riverpod
GetCategoryByIdUseCase getCategoryByIdUseCase(Ref ref) {
  final repository = ref.read(categoryRepositoryProvider);
  return GetCategoryByIdUseCase(repository);
}
  
  