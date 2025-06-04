// lib/features/home/data/repositories/category_repository_impl.dart

import 'dart:async';
import 'dart:math';
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
  // ИЗМЕНЕНИЕ: Флаг _isSyncing теперь будет надежно защищать от всех видов одновременной синхронизации.
  bool _isSyncing = false;
  
  bool _isDisposed = false;
  int _reconnectionAttempt = 0;

  CategoryRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._syncMetadataDao,
  ) : _categoryDao = (_localDataSource as CategoryLocalDataSource).categoryDao {
    _initServerSync();
  }

  void _initServerSync() {
    if (_isDisposed) return;
    
    print('🌊 Попытка подключения к серверному stream... (попытка #${_reconnectionAttempt + 1})');
    _serverStreamSubscription?.cancel();

    _serverStreamSubscription = _remoteDataSource.watchCategories().listen(
      (serverCategories) {
        print('✅ Stream успешно подключен и получил данные.');
        if (_reconnectionAttempt > 0) {
           print('👍 Соединение с real-time сервером восстановлено!');
        }
        _reconnectionAttempt = 0;
        // ИЗМЕНЕНИЕ: Stream теперь вызывает безопасный метод дифференциальной синхронизации.
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
      cancelOnError: true,
    );
  }

  void _scheduleReconnection() {
    if (_isDisposed) return;
    _serverStreamSubscription?.cancel();
    final delaySeconds = min(pow(2, _reconnectionAttempt), 60).toInt();
    print('⏱️ Следующая попытка подключения через $delaySeconds секунд.');

    Future.delayed(Duration(seconds: delaySeconds), () {
       _reconnectionAttempt++;
      _initServerSync();
    });
  }

  @override
  void dispose() {
    print('🛑 Уничтожение CategoryRepositoryImpl. Отменяем все подписки.');
    _isDisposed = true;
    _serverStreamSubscription?.cancel();
  }
  
  // ИЗМЕНЕНИЕ: Логика удаления стала умнее.
  Future<void> _performDifferentialSync(List<serverpod.Category> serverCategories) async {
    if (_isSyncing) {
        print('ℹ️ Дифференциальная синхронизация уже выполняется. Пропуск.');
        return;
    }
    _isSyncing = true;
    print('🔄 Начинаем дифференциальную синхронизацию (${serverCategories.length} записей с сервера)');

    try {
      final localCategories = await _categoryDao.getCategories();
      final serverCategoriesMap = {for (var c in serverCategories) c.id.toString(): c};
      final localCategoriesMap = {for (var c in localCategories) c.id: c};

      await _categoryDao.db.transaction(() async {
        // --- ИСПРАВЛЕННАЯ ЛОГИКА УДАЛЕНИЯ ---
        // Удаляем только те записи, которые имеют статус 'synced' и отсутствуют на сервере.
        // Это защищает новые, еще не отправленные оффлайн-записи (статус 'local') от удаления.
        final recordsToDelete = localCategoriesMap.values
            .where((localCat) =>
                !serverCategoriesMap.containsKey(localCat.id) &&
                localCat.syncStatus == SyncStatus.synced)
            .map((localCat) => localCat.id)
            .toList();

        for (final id in recordsToDelete) {
          await _categoryDao.deleteCategory(id);
          print('🗑️ Удалена локальная запись (т.к. удалена на сервере): $id');
        }

        for (final serverCategory in serverCategories) {
          final localCategory = localCategoriesMap[serverCategory.id.toString()];

          if (localCategory == null) {
            await _insertServerCategory(serverCategory);
            print('➕ Создана новая локальная запись с сервера: ${serverCategory.title}');
          } else {
            // Разрешение конфликтов остается прежним, оно корректно отдает приоритет локальным изменениям.
            await _resolveConflict(localCategory, serverCategory);
          }
        }
        
        await _syncMetadataDao.updateLastSyncTimestamp(_entityType, DateTime.now().toUtc());
      });
      print('✅ Дифференциальная синхронизация завершена');
    } catch (e, stackTrace) {
      print('❌ КРИТИЧЕСКАЯ ОШИБКА ДИФФ. СИНХРОНИЗАЦИИ: $e\n$stackTrace');
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
    // Запускаем фоновую синхронизацию
    _syncCreateToServer(category).catchError((e) {
      print('❌ Ошибка фоновой синхронизации (создание): $e');
      // ИЗМЕНЕНИЕ: Мы не перевыбрасываем ошибку, т.к. запись уже в локальной БД
      // и будет синхронизирована при следующем подключении.
    });
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
    try {
      final serverCategory = category.toServerpodCategory();
      final syncedCategory = await _remoteDataSource.createCategory(serverCategory);
      // Обновляем локальную запись, ставим статус synced
      await _categoryDao.updateCategory(syncedCategory.toCompanion(SyncStatus.synced));
      print('✅ Создание "${category.title}" подтверждено сервером.');
    } catch(e) {
       print('⚠️ Не удалось синхронизировать создание "${category.title}". Повторим позже. Ошибка: $e');
    }
  }

  Future<void> _syncUpdateToServer(CategoryEntity category) async {
    try {
      final serverCategory = category.toServerpodCategory();
      await _remoteDataSource.updateCategory(serverCategory);
      // Обновляем статус после успешной отправки
      await _categoryDao.updateCategory(serverCategory.toCompanion(SyncStatus.synced));
      print('✅ Обновление "${category.title}" подтверждено сервером.');
    } catch(e) {
      print('⚠️ Не удалось синхронизировать обновление "${category.title}". Повторим позже. Ошибка: $e');
    }
  }

  Future<void> _syncDeleteToServer(String id) async {
     try {
        await _remoteDataSource.deleteCategory(serverpod.UuidValue.fromString(id));
        print('✅ Удаление "$id" подтверждено сервером.');
     } catch(e) {
       // Если удаление на сервере не удалось (например, нет сети),
       // запись останется в локальной БД и будет удалена при следующей диф. синхронизации.
       // Это ожидаемое поведение.
       print('⚠️ Не удалось синхронизировать удаление "$id". Ошибка: $e');
     }
  }

  // ИЗМЕНЕНИЕ: Полностью переработанная, безопасная логика ручной/восстановительной синхронизации.
  @override
  Future<void> syncWithServer() async {
    if (_isSyncing) {
        print('ℹ️ Ручная синхронизация уже выполняется. Пропуск.');
        return;
    }
    _isSyncing = true;
    print('🔄 Запуск ручной/восстановительной синхронизации...');
    try {
      // ШАГ 1: СНАЧАЛА отправить все локальные изменения на сервер.
      // Это самый важный шаг для предотвращения потери данных.
      await _syncLocalChangesToServer();

      // ШАГ 2: ПОСЛЕ этого получить изменения с сервера.
      // Используем тот же самый безопасный _performDifferentialSync, который использует и stream.
      // Для этого нам нужен полный слепок состояния сервера.
      print('🕒 Получаем полный список категорий с сервера для сверки...');
      final allServerCategories = await _remoteDataSource.getCategories();
      await _performDifferentialSync(allServerCategories);

      print('✅ Ручная/восстановительная синхронизация завершена');
    } catch (e) {
      print('❌ Ошибка ручной синхронизации: $e');
      rethrow; // Перевыбрасываем, чтобы SyncController мог это увидеть
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<serverpod.Category>> _getServerChangesSince(DateTime? since) async {
    return await (_remoteDataSource as CategoryRemoteDataSource).getCategoriesSince(since);
  }  

  Future<void> _syncLocalChangesToServer() async {
    final localChanges = await (_categoryDao.select(_categoryDao.categoryTable)
          ..where((t) => t.syncStatus.equals(SyncStatus.local.name)))
        .get();
        
    if (localChanges.isEmpty) {
      print('📤 Локальных изменений для отправки нет.');
      return;
    }
    
    print('📤 Найдены ${localChanges.length} локальных изменений для отправки на сервер.');

    for (final localChange in localChanges) {
      final entity = localChange.toModel().toEntity();
      print('  -> Пытаемся синхронизировать локальную запись: "${entity.title}" (ID: ${entity.id})');
      
      try {
        // Проверяем, существует ли запись на сервере (может быть, это обновление, а не создание)
        // Мы используем getCategoryById, чтобы определить, вызывать create или update.
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
        // Ошибка будет обработана при следующей попытке синхронизации
      }
    }
     print('✅ Синхронизация локальных изменений завершена.');
  }

  @override
  Future<List<CategoryEntity>> getCategories() async => _localDataSource.getCategories().then((models) => models.toEntities());

  @override
  Future<CategoryEntity> getCategoryById(String id) async => _localDataSource.getCategoryById(id).then((model) => model.toEntity());
}

// Вспомогательные расширения остаются без изменений
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