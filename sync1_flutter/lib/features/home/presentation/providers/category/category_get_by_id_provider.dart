// lib/features/home/presentation/providers/category/category_get_by_id_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/entities/category/category.dart';
import '../../../domain/providers/category/category_usecase_providers.dart';
import 'category_state_providers.dart';

part 'category_get_by_id_provider.g.dart';

@riverpod
Future<CategoryEntity?> getCategoryById(GetCategoryByIdRef ref, String id) async {
  // Читаем текущее значение из нового StreamProvider
  final categoriesAsyncValue = ref.watch(categoriesStreamProvider);

  // Пытаемся найти категорию в кеше (в текущем состоянии стрима)
  // чтобы избежать лишнего запроса к базе
  if (categoriesAsyncValue.hasValue) {
    final category = categoriesAsyncValue.value?.firstWhere(
      (cat) => cat.id == id,
      orElse: () => const CategoryEntity(id: 'NOT_FOUND', title: ''), // Временный объект, если не найдено
    );
    // Если нашли реальный объект, возвращаем его
    if (category != null && category.id != 'NOT_FOUND') {
      return category;
    }
  }
  
  // Если в кеше нет или кеш еще не загружен, делаем прямой запрос к базе
  final categoryFromDb = await ref.read(getCategoryByIdUseCaseProvider)(id);
  return categoryFromDb;
}