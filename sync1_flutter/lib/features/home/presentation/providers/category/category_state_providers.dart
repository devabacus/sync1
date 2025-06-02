import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/entities/category/category.dart';
import '../../../domain/providers/category/category_usecase_providers.dart';

part 'category_state_providers.g.dart';

// Создаем StreamProvider, который будет автоматически обновлять UI
// при любых изменениях в таблице категорий в локальной БД.
@riverpod
Stream<List<CategoryEntity>> categoriesStream(Ref ref) {
  // Мы просто "слушаем" use case, который возвращает stream.
  // Riverpod автоматически обработает подписку и отписку.
  return ref.watch(watchCategoriesUseCaseProvider)();
}