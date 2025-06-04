// lib/features/home/data/repositories/category_repository_impl.dart

import 'dart:async';
import 'dart:math'; // Импортируем для использования функции max
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
  bool _isSyncing = false;
  
  // --- НОВЫЕ ПОЛЯ ДЛЯ УПРАВЛЕНИЯ ПЕРЕПОДКЛЮЧЕНИЕМ ---
  bool _isDisposed = false; // Флаг, что репозиторий уничтожен
  int _reconnectionAttempt = 0; // Счетчик попыток переподключения

  CategoryRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._syncMetadataDao,
  ) : _categoryDao = (_localDataSource as CategoryLocalDataSource).categoryDao {
    // Запускаем нашу "живучую" подписку
    _initServerSync();
  }

  /// Инициализирует и поддерживает постоянное подключение к серверному stream.
  void _initServerSync() {
    if (_isDisposed) return; // Не пытаться подключиться, если репозиторий уже уничтожен
    
    print('🌊 Попытка подключения к серверному stream... (попытка #${_reconnectionAttempt + 1})');

    // Отменяем старую подписку, если она вдруг осталась
    _serverStreamSubscription?.cancel();

    // Подписываемся на stream
    _serverStreamSubscription = _remoteDataSource.watchCategories().listen(
      (serverCategories) {
        // Успешное подключение и получение данных
        print('✅ Stream успешно подключен и получил данные.');
        if (_reconnectionAttempt > 0) {
           print('👍 Соединение с real-time сервером восстановлено!');
        }
        _reconnectionAttempt = 0; // Сбрасываем счетчик при успехе
        _performDifferentialSync(serverCategories);
      },
      onError: (error) {
        print('❌ Ошибка серверного стрима: $error. Планируем переподключение...');
        _scheduleReconnection();
      },
      onDone: () {
        print('🔌 Серверный stream был закрыт (onDone). Планируем переподключение...');
        _scheduleReconnection();
      },
      cancelOnError: true, // Важно: автоматически отписываться при ошибке
    );
  }

  /// Планирует следующую попытку переподключения с экспоненциальной задержкой.
  void _scheduleReconnection() {
    if (_isDisposed) return; // Не планировать, если репозиторий уничтожен

    // Отменяем подписку, чтобы избежать "зомби"
    _serverStreamSubscription?.cancel();

    // Экспоненциальная задержка: 2, 4, 8, 16, 32, 60 секунд (максимум)
    final delaySeconds = min(pow(2, _reconnectionAttempt), 60).toInt();
    print('⏱️ Следующая попытка подключения через $delaySeconds секунд.');

    Future.delayed(Duration(seconds: delaySeconds), () {
       _reconnectionAttempt++;
      _initServerSync(); // Повторная попытка подключения
    });
  }

  // --- ОСТАЛЬНОЙ КОД РЕПОЗИТОРИЯ ОСТАЕТСЯ БЕЗ ИЗМЕНЕНИЙ ---
  // (Я привожу его полностью для простоты копирования)

  @override
  void dispose() {
    print('🛑 Уничтожение CategoryRepositoryImpl. Отменяем все подписки.');
    _isDisposed = true; // Устанавливаем флаг, чтобы остановить переподключения
    _serverStreamSubscription?.cancel();
  }
  
  Future<void> _performDifferentialSync(List<serverpod.Category> serverCategories) async {
    if (_isSyncing) return;
    _isSyncing = true;
    print('🔄 Начинаем дифференциальную синхронизацию (${serverCategories.length} записей с сервера)');

    try {
      final localCategories = await _categoryDao.getCategories();
      final serverCategoriesMap = {for (var c in serverCategories) c.id.toString(): c};
      final localCategoriesMap = {for (var c in localCategories) c.id: c};

      await _categoryDao.db.transaction(() async {
        final recordsToDelete = localCategoriesMap.keys.toSet().difference(serverCategoriesMap.keys.toSet());
        for (final id in recordsToDelete) {
          await _categoryDao.deleteCategory(id);
          print('🗑️ Удалена локальная запись: $id');
        }

        for (final serverCategory in serverCategories) {
          final localCategory = localCategoriesMap[serverCategory.id.toString()];

          if (localCategory == null) {
            await _insertServerCategory(serverCategory);
            print('➕ Создана новая локальная запись: ${serverCategory.title}');
          } else {
            await _resolveConflict(localCategory, serverCategory);
          }
        }
        
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
    return await (_remoteDataSource as CategoryRemoteDataSource).getCategoriesSince(since);
  }  

  Future<void> _syncLocalChangesToServer() async {
    final localChanges = await (_categoryDao.select(_categoryDao.categoryTable)
          ..where((t) => t.syncStatus.equals(SyncStatus.local.name)))
        .get();
        
    print('📤 Найдены ${localChanges.length} локальных изменений для отправки на сервер.');

    if (localChanges.isEmpty) return;

    for (final localChange in localChanges) {
      final entity = localChange.toModel().toEntity();
      print('  -> Пытаемся синхронизировать локальную запись: "${entity.title}" (ID: ${entity.id})');
      
      try {
        final serverRecord = await _remoteDataSource.getCategoryById(serverpod.UuidValue.fromString(entity.id));
        
        if (serverRecord != null) {
          print('    -- Запись существует на сервере. Обновляем...');
          await _syncUpdateToServer(entity);
        } else {
          print('    -- Запись новая. Создаем на сервере...');
          await _syncCreateToServer(entity);
        }
      } catch (e) {
        print('❌ Ошибка синхронизации локальной записи ${localChange.id}: $e');
      }
    }
  }

  @override
  Future<List<CategoryEntity>> getCategories() async => _localDataSource.getCategories().then((models) => models.toEntities());

  @override
  Future<CategoryEntity> getCategoryById(String id) async => _localDataSource.getCategoryById(id).then((model) => model.toEntity());
}

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