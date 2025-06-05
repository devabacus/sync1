import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/database/local/provider/database_provider.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../datasources/local/dao/category/category_dao.dart';
import '../../datasources/local/dao/category/sync_metadata_dao.dart';
import '../../datasources/local/interfaces/category_local_datasource_service.dart';
import '../../datasources/local/sources/category_local_data_source.dart';
import '../../repositories/category_repository_impl.dart';
import 'category_remote_data_providers.dart';

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
  // Получаем все зависимости
  final localDataSource = ref.watch(categoryLocalDataSourceProvider);
  final remoteDataSource = ref.watch(categoryRemoteDataSourceProvider);
  final syncMetadataDao = ref.watch(syncMetadataDaoProvider);

  // Создаем репозиторий с передачей ref для доступа к провайдерам
  final repository = CategoryRepositoryImpl(
    localDataSource, 
    remoteDataSource, 
    syncMetadataDao,
    ref, // Передаем ref для доступа к currentUserProvider
  );

  // Убедимся, что при уничтожении провайдера подписка будет закрыта
  ref.onDispose(() => repository.dispose());

  return repository;
}

@riverpod
SyncMetadataDao syncMetadataDao(Ref ref) {
  final databaseService = ref.read(databaseServiceProvider);
  return SyncMetadataDao(databaseService.database);
}