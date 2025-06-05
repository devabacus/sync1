import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:sync1/features/home/data/datasources/local/tables/extensions/category_table_extension.dart';
import 'package:sync1/features/home/data/models/extensions/category_model_extension.dart';
import 'package:sync1/features/home/domain/entities/extensions/category_entity_extension.dart';
import 'package:sync1_client/sync1_client.dart' as serverpod;

import '../../../../core/database/local/database.dart';
import '../../../../core/providers/session_manager_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local/dao/category/category_dao.dart';
import '../datasources/local/dao/category/sync_metadata_dao.dart';
import '../datasources/local/interfaces/category_local_datasource_service.dart';
import '../datasources/local/sources/category_local_data_source.dart';
import '../datasources/local/tables/category_table.dart';
import '../datasources/remote/interfaces/category_remote_datasource_service.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  static const String _entityType = 'categories';

  final ICategoryLocalDataSource _localDataSource;
  final ICategoryRemoteDataSource _remoteDataSource;
  final SyncMetadataDao _syncMetadataDao;
  final CategoryDao _categoryDao;
  final Ref _ref; // Добавляем Ref для доступа к провайдерам

  StreamSubscription? _eventStreamSubscription;
  bool _isSyncing = false;
  bool _isDisposed = false;
  int _reconnectionAttempt = 0;

  CategoryRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._syncMetadataDao,
    this._ref, // Добавляем в конструктор
  ) : _categoryDao = (_localDataSource as CategoryLocalDataSource).categoryDao {
    _initEventBasedSync();
  }

  // Получаем текущего пользователя
  int? get _currentUserId {
    final user = _ref.read(currentUserProvider);
    return user?.id;
  }

  void _initEventBasedSync() {
    if (_isDisposed) return;

    print('🌊 Попытка подписки на события сервера... (попытка #${_reconnectionAttempt + 1})');
    _eventStreamSubscription?.cancel();

    _eventStreamSubscription = _remoteDataSource.watchEvents().listen(
      (event) {
        print('⚡️ Получено событие с сервера: ${event.type.name}');
        if (_reconnectionAttempt > 0) {
          print('👍 Соединение с real-time сервером восстановлено!');
        }
        _reconnectionAttempt = 0;
        _handleSyncEvent(event);
      },
      onError: (error) {
        print('❌ Ошибка стрима событий: $error. Планируем переподключение...');
        _scheduleReconnection();
      },
      onDone: () {
        print('🔌 Стрим событий был закрыт (onDone). Планируем переподключение...');
        _scheduleReconnection();
      },
      cancelOnError: true,
    );
  }

  void _scheduleReconnection() {
    if (_isDisposed) return;
    _eventStreamSubscription?.cancel();
    final delaySeconds = min(pow(2, _reconnectionAttempt), 60).toInt();
    print('⏱️ Следующая попытка подключения через $delaySeconds секунд.');

    Future.delayed(Duration(seconds: delaySeconds), () {
      _reconnectionAttempt++;
      _initEventBasedSync();
    });
  }

  @override
  void dispose() {
    print('🛑 Уничтожение CategoryRepositoryImpl. Отменяем все подписки.');
    _isDisposed = true;
    _eventStreamSubscription?.cancel();
  }

  Future<void> _handleSyncEvent(serverpod.CategorySyncEvent event) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return; // Игнорируем события, если пользователь не авторизован

    switch (event.type) {
      case serverpod.SyncEventType.create:
        if (event.category != null && event.category!.userId == currentUserId) {
          await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
              event.category!.toCompanion(SyncStatus.synced));
          print('  -> Локально СОЗДАНА категория "${event.category!.title}" по событию с сервера.');
        }
        break;
      case serverpod.SyncEventType.update:
        if (event.category != null && event.category!.userId == currentUserId) {
          final localCopy = await (_categoryDao.select(_categoryDao.categoryTable)
                ..where((t) => t.id.equals(event.category!.id.toString())))
              .getSingleOrNull();

          if (localCopy?.syncStatus == SyncStatus.local) {
            print('  -> КОНФЛИКТ: Локальные изменения для "${localCopy!.title}" имеют приоритет. Серверное обновление проигнорировано.');
          } else {
            await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
                event.category!.toCompanion(SyncStatus.synced));
            print('  -> Локально ОБНОВЛЕНА категория "${event.category!.title}" по событию с сервера.');
          }
        }
        break;
      case serverpod.SyncEventType.delete:
        if (event.id != null) {
          // Проверяем, что удаляемая запись принадлежит текущему пользователю
          final localRecord = await (_categoryDao.select(_categoryDao.categoryTable)
                ..where((t) => t.id.equals(event.id!.toString())))
              .getSingleOrNull();
          
          if (localRecord?.userId == currentUserId) {
            await _categoryDao.physicallyDeleteCategory(event.id!.toString());
            print('  -> Локально УДАЛЕНА категория с ID "${event.id}" по событию с сервера.');
          }
        }
        break;
    }
  }

  @override
  Future<void> syncWithServer() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      print('❌ Синхронизация невозможна: пользователь не авторизован');
      return;
    }

    if (_isSyncing) {
      print('ℹ️ Ручная синхронизация уже выполняется. Пропуск.');
      return;
    }
    _isSyncing = true;
    print('🔄 Запуск ручной/восстановительной синхронизации для пользователя $currentUserId...');
    try {
      await _syncLocalChangesToServer();

      print('🕒 Получаем полный список категорий с сервера для сверки...');
      final allServerCategories = await _remoteDataSource.getCategories();

      await _applyServerState(allServerCategories);

      print('✅ Ручная/восстановительная синхронизация завершена');
    } catch (e) {
      print('❌ Ошибка ручной синхронизации: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _applyServerState(List<serverpod.Category> serverCategories) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    print('⚙️ Применение состояния сервера (${serverCategories.length} записей)...');
    try {
      final localCategories = await _categoryDao.getCategories(userId: currentUserId);
      final serverCategoriesMap = {
        for (var c in serverCategories) c.id.toString(): c
      };
      final localCategoriesMap = {for (var c in localCategories) c.id: c};

      await _categoryDao.db.transaction(() async {
        final recordsToDelete = localCategoriesMap.values
            .where((localCat) =>
                !serverCategoriesMap.containsKey(localCat.id) &&
                localCat.syncStatus == SyncStatus.synced &&
                localCat.userId == currentUserId)
            .map((localCat) => localCat.id)
            .toList();

        if (recordsToDelete.isNotEmpty) {
          print('🗑️ Будет удалено ${recordsToDelete.length} записей, отсутствующих на сервере.');
          for (final id in recordsToDelete) {
            await _categoryDao.physicallyDeleteCategory(id);
          }
        }

        for (final serverCategory in serverCategories) {
          if (serverCategory.userId == currentUserId) {
            final localCategory = localCategoriesMap[serverCategory.id.toString()];

            if (localCategory == null) {
              await _insertServerCategory(serverCategory);
            } else {
              await _resolveConflict(localCategory, serverCategory);
            }
          }
        }

        await _syncMetadataDao.updateLastSyncTimestamp(_entityType, DateTime.now().toUtc());
      });
      print('✅ Состояние сервера успешно применено.');
    } catch (e, stackTrace) {
      print('❌ КРИТИЧЕСКАЯ ОШИБКА применения состояния сервера: $e\n$stackTrace');
    }
  }

  Future<void> _insertServerCategory(serverpod.Category serverCategory) async {
    print('➕ Создана новая локальная запись с сервера: ${serverCategory.title}');
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
      print('🔄 Обновлена локальная запись: ${server.title}');
      await _categoryDao.updateCategory(server.toCompanion(SyncStatus.synced));
    }
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    final currentUserId = _currentUserId;
    return _localDataSource
        .watchCategories(userId: currentUserId)
        .map((models) => models.toEntities());
  }

  @override
  Future<String> createCategory(CategoryEntity category) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('Пользователь не авторизован');
    }

    final categoryWithUser = category.copyWith(userId: currentUserId);
    final companion = categoryWithUser
        .toModel()
        .toCompanion()
        .copyWith(syncStatus: const Value(SyncStatus.local));
    
    await _categoryDao.createCategory(companion);
    _syncCreateToServer(categoryWithUser).catchError((e) {
      print('⚠️ Не удалось синхронизировать создание "${categoryWithUser.title}". Повторим позже. Ошибка: $e');
    });
    return categoryWithUser.id;
  }

  @override
  Future<bool> updateCategory(CategoryEntity category) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('Пользователь не авторизован');
    }

    final categoryWithUser = category.copyWith(userId: currentUserId);
    final companion = categoryWithUser
        .toModel()
        .toCompanion()
        .copyWith(syncStatus: const Value(SyncStatus.local));
    
    final result = await _categoryDao.updateCategory(companion);
    _syncUpdateToServer(categoryWithUser).catchError((e) => print(
        '⚠️ Не удалось синхронизировать обновление "${categoryWithUser.title}". Повторим позже. Ошибка: $e'));
    return result;
  }

  @override
  Future<bool> deleteCategory(String id) async {
    final result = await _categoryDao.softDeleteCategory(id);
    _syncDeleteToServer(id).catchError(
        (e) => print('⚠️ Не удалось синхронизировать удаление "$id". Ошибка: $e'));
    return result;
  }

  Future<void> _syncCreateToServer(CategoryEntity category) async {
    try {
      final serverCategory = category.toServerpodCategory();
      final syncedCategory = await _remoteDataSource.createCategory(serverCategory);
      await _categoryDao.updateCategory(syncedCategory.toCompanion(SyncStatus.synced));
      print('✅ Создание "${category.title}" подтверждено сервером.');
    } catch (e) {
      print('⚠️ Ошибка при подтверждении создания "${category.title}": $e');
      rethrow;
    }
  }

  Future<void> _syncUpdateToServer(CategoryEntity category) async {
    try {
      final serverCategory = category.toServerpodCategory();
      await _remoteDataSource.updateCategory(serverCategory);
      await _categoryDao.updateCategory(serverCategory.toCompanion(SyncStatus.synced));
      print('✅ Обновление "${category.title}" подтверждено сервером.');
    } catch (e) {
      print('⚠️ Ошибка при подтверждении обновления "${category.title}": $e');
      rethrow;
    }
  }

  Future<void> _syncDeleteToServer(String id) async {
    try {
      await _remoteDataSource.deleteCategory(serverpod.UuidValue.fromString(id));
      print('✅ Удаление "$id" подтверждено сервером.');
    } catch (e) {
      print('⚠️ Не удалось синхронизировать удаление "$id". Ошибка: $e');
      rethrow;
    }
  }

  Future<void> _syncLocalChangesToServer() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    final localChanges = await (_categoryDao.select(_categoryDao.categoryTable)
          ..where((t) =>
              (t.syncStatus.equals(SyncStatus.local.name) |
               t.syncStatus.equals(SyncStatus.deleted.name)) &
              t.userId.equals(currentUserId)))
        .get();

    if (localChanges.isEmpty) {
      print('📤 Локальных изменений для отправки нет.');
      return;
    }

    print('📤 Найдены ${localChanges.length} локальных изменений для отправки на сервер.');

    for (final localChange in localChanges) {
      if (localChange.syncStatus == SyncStatus.deleted) {
        print('  -> Пытаемся синхронизировать удаление для ID: ${localChange.id}');
        try {
          await _syncDeleteToServer(localChange.id);
          await _categoryDao.physicallyDeleteCategory(localChange.id);
          print('  ✅ "Надгробие" для ID ${localChange.id} очищено после синхронизации.');
        } catch (e) {
          print('  -> Попытка синхронизации удаления для ID ${localChange.id} не удалась. Повторим позже.');
        }
      } else if (localChange.syncStatus == SyncStatus.local) {
        final entity = localChange.toModel().toEntity();
        print('  -> Пытаемся синхронизировать создание/обновление: "${entity.title}"');

        try {
          final serverRecord = await _remoteDataSource
              .getCategoryById(serverpod.UuidValue.fromString(entity.id));

          if (serverRecord != null) {
            await _syncUpdateToServer(entity);
          } else {
            await _syncCreateToServer(entity);
          }
        } catch (e) {
          print('❌ Ошибка синхронизации для записи ${localChange.id}: $e');
        }
      }
    }
    print('✅ Синхронизация локальных изменений завершена.');
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final currentUserId = _currentUserId;
    return _localDataSource
        .getCategories(userId: currentUserId)
        .then((models) => models.toEntities());
  }

  @override
  Future<CategoryEntity> getCategoryById(String id) async =>
      _localDataSource.getCategoryById(id).then((model) => model.toEntity());
}

extension on CategoryEntity {
  serverpod.Category toServerpodCategory() => serverpod.Category(
        id: serverpod.UuidValue.fromString(id),
        title: title,
        lastModified: lastModified,
        userId: userId,
      );
}

extension on serverpod.Category {
  CategoryTableCompanion toCompanion(SyncStatus status) =>
      CategoryTableCompanion(
        id: Value(id.toString()),
        title: Value(title),
        lastModified: Value(lastModified ?? DateTime.now()),
        userId: Value(userId),
        syncStatus: Value(status),
      );
}