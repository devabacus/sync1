import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sync1_client/sync1_client.dart';

import '../../datasources/remote/interfaces/category_remote_datasource_service.dart';
import '../../datasources/remote/sources/category_remote_data_source.dart';
import '../../../../../core/providers/serverpod_client_provider.dart';

part 'category_remote_data_providers.g.dart';

/// Провайдер для Remote Data Source категорий
@riverpod
ICategoryRemoteDataSource categoryRemoteDataSource(Ref ref) {
  final client = ref.watch(serverpodClientProvider);
  final remoteDataSource = CategoryRemoteDataSource(client);
  
  // Автоматическая очистка ресурсов при dispose
  ref.onDispose(() async {
    await remoteDataSource.closeStreams();
  });
  
  return remoteDataSource;
}

/// Провайдер для проверки подключения к серверу
@riverpod
Future<bool> categoryRemoteConnectionCheck(Ref ref) async {
  final remoteDataSource = ref.watch(categoryRemoteDataSourceProvider);
  return await remoteDataSource.checkConnection();
}

/// Провайдер для получения категорий с сервера (разовый запрос)
@riverpod
Future<List<Category>> categoriesFromServer(Ref ref) async {
  final remoteDataSource = ref.watch(categoryRemoteDataSourceProvider);
  return await remoteDataSource.getCategories();
}

/// Провайдер для real-time потока категорий с сервера
@riverpod
Stream<List<Category>> categoriesStreamFromServer(Ref ref) {
  final remoteDataSource = ref.watch(categoryRemoteDataSourceProvider);
  return remoteDataSource.watchCategories();
}