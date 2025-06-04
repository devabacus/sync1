// lib/features/home/data/repositories/category_repository_impl.dart

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:sync1_client/sync1_client.dart' as serverpod;

import '../../../../core/database/local/database.dart';
import '../../domain/entities/category/category.dart';
import '../../domain/entities/extensions/category_entity_extension.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local/dao/category/category_dao.dart';
import '../datasources/local/dao/category/sync_metadata_dao.dart';
import '../datasources/local/interfaces/category_local_datasource_service.dart';
import '../datasources/local/sources/category_local_data_source.dart';
import '../datasources/local/tables/category_table.dart';
import '../datasources/local/tables/extensions/category_table_extension.dart';
import '../datasources/remote/interfaces/category_remote_datasource_service.dart';
import '../datasources/remote/sources/category_remote_data_source.dart';
import '../models/extensions/category_model_extension.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  static const String _entityType = 'categories';

  final ICategoryLocalDataSource _localDataSource;
  final ICategoryRemoteDataSource _remoteDataSource;
  final SyncMetadataDao _syncMetadataDao;
  final CategoryDao _categoryDao;

  StreamSubscription? _serverStreamSubscription;
  bool _isSyncing = false; // Флаг для предотвращения одновременных синхронизаций

  CategoryRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._syncMetadataDao,
  ) : _categoryDao = (_localDataSource as CategoryLocalDataSource).categoryDao {
    _initServerSync();
  }

  void _initServerSync() {
    if (_serverStreamSubscription != null) return;
    _serverStreamSubscription = _remoteDataSource.watchCategories().listen(
      (serverCategories) => _performDifferentialSync(serverCategories),
      onError: (error) => print('❌ Ошибка серверного стрима: $error'),
    );
  }

  /// ИСПРАВЛЕНО: Главный метод синхронизации. Теперь он более надежный.
  Future<void> _performDifferentialSync(List<serverpod.Category> serverCategories) async {
    if (_isSyncing) return;
    _isSyncing = true;
    print('🔄 Начинаем дифференциальную синхронизацию (${serverCategories.length} записей с сервера)');

    try {
      final localCategories = await _categoryDao.getCategories();
      final serverCategoriesMap = {for (var c in serverCategories) c.id.toString(): c};
      final localCategoriesMap = {for (var c in localCategories) c.id: c};

      await _categoryDao.db.transaction(() async {
        // 1. Удаление: Находим локальные записи, которых больше нет на сервере.
        final recordsToDelete = localCategoriesMap.keys.toSet().difference(serverCategoriesMap.keys.toSet());
        for (final id in recordsToDelete) {
          await _categoryDao.deleteCategory(id);
          print('🗑️ Удалена локальная запись: $id');
        }

        // 2. Создание и Обновление: Проходим по всем записям с сервера.
        for (final serverCategory in serverCategories) {
          final localCategory = localCategoriesMap[serverCategory.id.toString()];

          if (localCategory == null) {
            await _insertServerCategory(serverCategory);
            print('➕ Создана новая локальная запись: ${serverCategory.title}');
          } else {
            await _resolveConflict(localCategory, serverCategory);
          }
        }
        
        // Обновляем время последней синхронизации
        await _syncMetadataDao.updateLastSyncTimestamp(_entityType, DateTime.now().toUtc());
      });
      print('✅ Дифференциальная синхронизация завершена');
    } catch (e, stackTrace) {
      print('❌ КРИТИЧЕСКАЯ ОШИБКА СИНХРОНИЗАЦИИ: $e\n$stackTrace');
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<void> _insertServerCategory(serverpod.Category serverCategory) async {
    final companion = serverCategory.toCompanion(SyncStatus.synced);
    await _categoryDao.db.into(_categoryDao.categoryTable).insert(companion);
  }
  
  /// ИСПРАВЛЕНО: Логика сравнения теперь использует миллисекунды.
  Future<void> _resolveConflict(CategoryTableData local, serverpod.Category server) async {
    if (local.syncStatus == SyncStatus.local) {
      print('📝 Обнаружена локально измененная запись "${local.title}". Пропускаем обновление с сервера.');
      return;
    }
    
    final serverMillis = server.lastModified?.millisecondsSinceEpoch ?? 0;
    final localMillis = local.lastModified.millisecondsSinceEpoch;

    if (serverMillis > localMillis) {
      await _categoryDao.updateCategory(server.toCompanion(SyncStatus.synced));
      print('🔄 Обновлена локальная запись: ${server.title}');
    }
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    return _localDataSource.watchCategories().map((models) => models.toEntities());
  }

  /// ИСПРАВЛЕНО: Логика создания, обновления и удаления теперь подтверждает синхронизацию.
  @override
  Future<String> createCategory(CategoryEntity category) async {
    final companion = category.toModel().toCompanion().copyWith(syncStatus: const Value(SyncStatus.local));
    await _categoryDao.createCategory(companion);
    _syncCreateToServer(category).catchError((e) => print('❌ Ошибка фоновой синхронизации (создание): $e'));
    return category.id;
  }

  @override
  Future<bool> updateCategory(CategoryEntity category) async {
    final companion = category.toModel().toCompanion().copyWith(syncStatus: const Value(SyncStatus.local));
    final result = await _categoryDao.updateCategory(companion);
    _syncUpdateToServer(category).catchError((e) => print('❌ Ошибка фоновой синхронизации (обновление): $e'));
    return result;
  }

  @override
  Future<bool> deleteCategory(String id) async {
    final result = await _categoryDao.deleteCategory(id);
    _syncDeleteToServer(id).catchError((e) => print('❌ Ошибка фоновой синхронизации (удаление): $e'));
    return result;
  }

  // Приватные методы для отправки данных на сервер и обновления статуса локально
  Future<void> _syncCreateToServer(CategoryEntity category) async {
    final serverCategory = category.toServerpodCategory();
    final syncedCategory = await _remoteDataSource.createCategory(serverCategory);
    await _categoryDao.updateCategory(syncedCategory.toCompanion(SyncStatus.synced));
    print('✅ Создание "${category.title}" подтверждено сервером.');
  }

  Future<void> _syncUpdateToServer(CategoryEntity category) async {
    final serverCategory = category.toServerpodCategory();
    await _remoteDataSource.updateCategory(serverCategory);
    await _categoryDao.updateCategory(serverCategory.toCompanion(SyncStatus.synced));
    print('✅ Обновление "${category.title}" подтверждено сервером.');
  }

  Future<void> _syncDeleteToServer(String id) async {
    await _remoteDataSource.deleteCategory(serverpod.UuidValue.fromString(id));
    print('✅ Удаление "$id" подтверждено сервером.');
  }

  @override
  Future<void> syncWithServer() async {
    try {
      print('🔄 Запуск ручной синхронизации с сервером...');
      final lastSync = await _syncMetadataDao.getLastSyncTimestamp(_entityType);
      
      // ИСПРАВЛЕНО: Вызываем правильный метод для дельта-синхронизации
      final serverCategories = await _getServerChangesSince(lastSync);

      if (serverCategories.isNotEmpty) {
        await _performDifferentialSync(serverCategories);
      }
      await _syncLocalChangesToServer();
      print('✅ Ручная синхронизация завершена');
    } catch (e) {
      print('❌ Ошибка ручной синхронизации: $e');
      rethrow;
    }
  }

  Future<List<serverpod.Category>> _getServerChangesSince(DateTime? since) async {
    // ВАЖНО: Убедитесь, что ваш remoteDataSource имеет этот метод
    return await (_remoteDataSource as CategoryRemoteDataSource).getCategoriesSince(since);
  }  

  // lib/features/home/data/repositories/category_repository_impl.dart

  Future<void> _syncLocalChangesToServer() async {
    // 1. Находим все записи, которые нужно отправить
    final localChanges = await (_categoryDao.select(_categoryDao.categoryTable)
          ..where((t) => t.syncStatus.equals(SyncStatus.local.name)))
        .get();
        
    print('📤 Найдены ${localChanges.length} локальных изменений для отправки на сервер.');

    if (localChanges.isEmpty) return;

    // 2. Проходим по каждой записи и решаем, что с ней делать
    for (final localChange in localChanges) {
      final entity = localChange.toModel().toEntity();
      print('  -> Пытаемся синхронизировать локальную запись: "${entity.title}" (ID: ${entity.id})');
      
      try {
        // 3. Проверяем, существует ли запись на сервере, чтобы понять, создавать её или обновлять
        final serverRecord = await _remoteDataSource.getCategoryById(serverpod.UuidValue.fromString(entity.id));
        
        if (serverRecord != null) {
          // Если запись на сервере уже есть - значит, это было офлайн-ОБНОВЛЕНИЕ.
          print('    -- Запись существует на сервере. Обновляем...');
          await _syncUpdateToServer(entity);
        } else {
          // Если записи на сервере нет - значит, это было офлайн-СОЗДАНИЕ.
          print('    -- Запись новая. Создаем на сервере...');
          await _syncCreateToServer(entity);
        }
      } catch (e) {
        print('❌ Ошибка синхронизации локальной записи ${localChange.id}: $e');
        // В случае ошибки мы не меняем статус записи, оставляя ее `local`,
        // чтобы приложение попробовало синхронизировать ее в следующий раз.
      }
    }
  }

  @override
  void dispose() {
    _serverStreamSubscription?.cancel();
    _serverStreamSubscription = null;
  }

  @override
  Future<List<CategoryEntity>> getCategories() async => _localDataSource.getCategories().then((models) => models.toEntities());

  @override
  Future<CategoryEntity> getCategoryById(String id) async => _localDataSource.getCategoryById(id).then((model) => model.toEntity());
}


// Вспомогательные расширения для конвертации. Их можно вынести в отдельный файл.
extension on CategoryEntity {
  serverpod.Category toServerpodCategory() => serverpod.Category(
        id: serverpod.UuidValue.fromString(id),
        title: title,
        lastModified: lastModified,
      );
}

extension on serverpod.Category {
  CategoryTableCompanion toCompanion(SyncStatus status) => CategoryTableCompanion(
        id: Value(id.toString()),
        title: Value(title),
        lastModified: Value(lastModified ?? DateTime.now()),
        syncStatus: Value(status),
      );
}