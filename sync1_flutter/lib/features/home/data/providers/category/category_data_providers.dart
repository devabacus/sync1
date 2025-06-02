import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/database/local/provider/database_provider.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../datasources/local/dao/category/category_dao.dart';
import '../../datasources/local/interfaces/category_local_datasource_service.dart';
import '../../datasources/local/sources/category_local_data_source.dart';
import '../../repositories/category_repository_impl.dart';
import 'category_remote_data_providers.dart'; // <-- Наш новый импорт

part 'category_data_providers.g.dart';

@riverpod
CategoryDao categoryDao(Ref ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return CategoryDao(databaseService);
}

@riverpod
ICategoryLocalDataSource categoryLocalDataSource(Ref ref) {
  final categoryDao = ref.read(categoryDaoProvider);
  return CategoryLocalDataSource(categoryDao);
}

@riverpod
ICategoryRepository categoryRepository(Ref ref) {
  ref.keepAlive();
  // Получаем обе зависимости: локальную и удаленную
  final localDataSource = ref.watch(categoryLocalDataSourceProvider);
  final remoteDataSource = ref.watch(categoryRemoteDataSourceProvider); // <-- Новая зависимость

   // Создаем репозиторий, который автоматически начнет слушать сервер
  final repository = CategoryRepositoryImpl(localDataSource, remoteDataSource);

  // Убедимся, что при уничтожении провайдера подписка будет закрыта
  ref.onDispose(() => repository.dispose());

  // Передаем обе зависимости в конструктор
  return CategoryRepositoryImpl(localDataSource, remoteDataSource);
}

