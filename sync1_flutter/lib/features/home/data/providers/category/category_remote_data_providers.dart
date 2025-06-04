import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../datasources/remote/interfaces/category_remote_datasource_service.dart';
import '../../datasources/remote/sources/category_remote_data_source.dart';
import '../../../../../core/providers/serverpod_client_provider.dart';

part 'category_remote_data_providers.g.dart';

/// Провайдер для Remote Data Source категорий
@riverpod
ICategoryRemoteDataSource categoryRemoteDataSource(Ref ref) {
  ref.keepAlive();
  final client = ref.watch(serverpodClientProvider);
  final remoteDataSource = CategoryRemoteDataSource(client);
  
  // Автоматическая очистка ресурсов при dispose
  ref.onDispose(() async {
    // В старой версии здесь было closeStreams(), убедимся, что это есть в вашей реализации
    // remoteDataSource.dispose(); или аналогичный метод
  });
  
  return remoteDataSource;
}

/// Провайдер для проверки подключения к серверу
@riverpod
Future<bool> categoryRemoteConnectionCheck(Ref ref) async {
  final remoteDataSource = ref.watch(categoryRemoteDataSourceProvider);
  return await remoteDataSource.checkConnection();
}