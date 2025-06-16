// lib/features/home/data/repositories/category_repository_impl.dart

import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:sync1/features/home/data/datasources/local/tables/extensions/category_table_extension.dart';
import 'package:sync1/features/home/data/models/extensions/category_model_extension.dart';
import 'package:sync1/features/home/domain/entities/extensions/category_entity_extension.dart';
import 'package:sync1_client/sync1_client.dart' as serverpod;

import '../../../../core/database/local/database.dart';
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
  final int _userId;

  StreamSubscription? _eventStreamSubscription;
  bool _isSyncing = false;
  bool _isDisposed = false;
  int _reconnectionAttempt = 0;
  static const int _maxReconnectionAttempts = 5;

  CategoryRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._syncMetadataDao,
    this._userId,
  ) : _categoryDao = (_localDataSource as CategoryLocalDataSource).categoryDao {
    print('✅ CategoryRepositoryImpl: Создан экземпляр для userId: $_userId');
    _initEventBasedSync();
  }
<<<<<<< HEAD

  // --- НОВАЯ СХЕМА СИНХРОНИЗАЦИИ ---
=======
  
  // --- НОВАЯ, НАДЕЖНАЯ РЕАЛИЗАЦИЯ СИНХРОНИЗАЦИИ ---
>>>>>>> master
  @override
  Future<void> syncWithServer() async {
    if (_isSyncing) {
      print('ℹ️ Синхронизация уже выполняется для пользователя $_userId. Пропуск.');
      return;
    }
    _isSyncing = true;
    print('🔄 Запуск синхронизации для пользователя $_userId...');

    try {
<<<<<<< HEAD
      final lastSync = await _syncMetadataDao.getLastSyncTimestamp(_entityType);

      // --- ШАГ 1: ПОЛУЧАЕМ ИЗМЕНЕНИЯ С СЕРВЕРА ---
=======
      final lastSync = await _syncMetadataDao.getLastSyncTimestamp(_entityType, userId: _userId);

      // --- ШАГ 1: СНАЧАЛА ПОЛУЧАЕМ ИЗМЕНЕНИЯ С СЕРВЕРА ---
>>>>>>> master
      print('  [1/3] Получение изменений с сервера с момента: $lastSync');
      final serverChanges = await _remoteDataSource.getCategoriesSince(lastSync);
      print('    -> Получено ${serverChanges.length} изменений с сервера.');

      // --- ШАГ 2: РАЗРЕШЕНИЕ КОНФЛИКТОВ И СЛИЯНИЕ ---
      print('  [2/3] Слияние данных и разрешение конфликтов...');
      final localChangesToPush = await _reconcileChanges(serverChanges);
      print('    -> ${localChangesToPush.length} локальных изменений готовы к отправке.');

      // --- ШАГ 3: ОТПРАВКА ОСТАВШИХСЯ ЛОКАЛЬНЫХ ИЗМЕНЕНИЙ ---
      if (localChangesToPush.isNotEmpty) {
        print('  [3/3] Отправка локальных изменений на сервер...');
        await _pushLocalChanges(localChangesToPush);
      } else {
        print('  [3/3] Нет локальных изменений для отправки.');
      }

      // В случае успеха обновляем метку времени
<<<<<<< HEAD
      await _syncMetadataDao.updateLastSyncTimestamp(_entityType, DateTime.now().toUtc());
=======
      await _syncMetadataDao.updateLastSyncTimestamp(_entityType, DateTime.now().toUtc(), userId: _userId);
>>>>>>> master
      print('✅ Синхронизация успешно завершена для пользователя $_userId');

    } catch (e) {
      print('❌ Ошибка синхронизации для пользователя $_userId: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Метод для слияния серверных изменений с локальными и разрешения конфликтов.
  /// Возвращает список локальных изменений, которые нужно отправить на сервер.
  Future<List<CategoryTableData>> _reconcileChanges(List<serverpod.Category> serverChanges) async {
<<<<<<< HEAD
    // Получаем все несинхронизированные локальные изменения
=======
    // Получаем все локальные записи, которые были изменены (статус не 'synced')
>>>>>>> master
    final allLocalChanges = await (_categoryDao.select(_categoryDao.categoryTable)
          ..where((t) => (t.syncStatus.equals(SyncStatus.synced.name)).not() & t.userId.equals(_userId)))
        .get();

<<<<<<< HEAD
    final localChangesMap = {for (var c in allLocalChanges) c.id: c};

    await _categoryDao.db.transaction(() async {
      for (final serverChange in serverChanges) {
        // Пропускаем записи, не принадлежащие пользователю
        if (serverChange.userId != _userId) continue;

=======
    // Создаем карту для быстрого доступа к локальным изменениям и для отслеживания тех, что нужно будет отправить на сервер
    final localChangesMap = {for (var c in allLocalChanges) c.id: c};

    // Выполняем все операции в рамках одной транзакции для целостности данных
    await _categoryDao.db.transaction(() async {
      for (final serverChange in serverChanges) {
        // Пропускаем записи, которые по какой-то причине пришли для другого пользователя
        if (serverChange.userId != _userId) continue;

        // --- БЛОК ОБРАБОТКИ УДАЛЕНИЯ (С РАСШИРЕННЫМ ЛОГИРОВАНИЕМ) ---
        if (serverChange.isDeleted) {
          final idToDelete = serverChange.id.toString();
          print('    -> ПОЛУЧЕНО НАДГРОБИЕ с сервера для ID: $idToDelete. Пытаемся удалить локально...');

          // ШАГ ДИАГНОСТИКИ 1: Проверяем, существует ли запись ПЕРЕД удалением
          final recordExists = await (_categoryDao.select(_categoryDao.categoryTable)
                ..where((t) => t.id.equals(idToDelete) & t.userId.equals(_userId)))
              .getSingleOrNull();

          if (recordExists != null) {
            print('    -> ✅ Локальная запись для удаления найдена: ID=${recordExists.id}, Title="${recordExists.title}". Выполняем удаление...');
            
            // ШАГ ДИАГНОСТИКИ 2: Выполняем удаление и смотрим на результат
            final deletedRowsCount = await _categoryDao.physicallyDeleteCategory(idToDelete, userId: _userId);
            
            print('    -> ⚙️ Результат операции: $deletedRowsCount строк удалено.');
            
            if(deletedRowsCount == 0) {
                print('    -> ❌ КРИТИЧЕСКАЯ ОШИБКА: Запись была найдена, но не была удалена. Проверьте логику DAO или транзакции.');
            }

          } else {
            print('    -> ⚠️ Локальная запись с ID $idToDelete для пользователя $_userId не найдена. Удаление не требуется.');
          }
          
          // Удаляем запись из карты локальных изменений, т.к. серверное удаление имеет приоритет
          localChangesMap.remove(idToDelete);
          // Переходим к следующему изменению с сервера
          continue; 
        }
        // --- КОНЕЦ БЛОКА УДАЛЕНИЯ ---

        // Ищем локальную запись, соответствующую изменению с сервера
>>>>>>> master
        final localRecord = await (_categoryDao.select(_categoryDao.categoryTable)
              ..where((t) => t.id.equals(serverChange.id.toString())))
            .getSingleOrNull();

<<<<<<< HEAD
        if (localRecord == null) {
          // Записи нет локально, создаем ее с сервера
=======
        // Если локальной записи нет, и это не "надгробие" - просто создаем ее.
        if (localRecord == null) {
>>>>>>> master
          await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
                serverChange.toCompanion(SyncStatus.synced),
              );
          print('    -> СОЗДАНО с сервера: "${serverChange.title}"');
<<<<<<< HEAD
          continue;
        }

        // Если есть локальные несинхронизированные изменения
        if (localRecord.syncStatus == SyncStatus.local || localRecord.syncStatus == SyncStatus.deleted) {
          // РАЗРЕШЕНИЕ КОНФЛИКТА ПО ВРЕМЕНИ
          final serverTime = serverChange.lastModified ?? DateTime.fromMicrosecondsSinceEpoch(0);
          final localTime = localRecord.lastModified;
          
          if (serverTime.isAfter(localTime)) {
            // Сервер новее - применяем серверные изменения
=======
          continue; // Переходим к следующему изменению
        }

        // Если у локальной записи есть несохраненные изменения (статус local или deleted)
        if (localRecord.syncStatus == SyncStatus.local || localRecord.syncStatus == SyncStatus.deleted) {
          final serverTime = serverChange.lastModified ?? DateTime.fromMicrosecondsSinceEpoch(0);
          final localTime = localRecord.lastModified;
          
          // Конфликт: разрешаем в пользу более новой записи (lastModified)
          if (serverTime.isAfter(localTime)) {
>>>>>>> master
            print('    -> КОНФЛИКТ: Сервер новее для "${serverChange.title}". Применяем серверные изменения.');
            await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
                  serverChange.toCompanion(SyncStatus.synced),
                );
<<<<<<< HEAD
            // Удаляем из списка на отправку - конфликт решен в пользу сервера
            localChangesMap.remove(localRecord.id);
          } else if (serverTime.isBefore(localTime)) {
            // Локальная версия новее - она будет отправлена на сервер
            print('    -> КОНФЛИКТ: Локальная версия новее для "${localRecord.title}". Будет отправлена на сервер.');
            // Локальная запись остается в localChangesMap
          } else {
            // Время одинаковое - приоритет локальным изменениям
            print('    -> КОНФЛИКТ: Время одинаковое для "${localRecord.title}". Приоритет локальным изменениям.');
            // Локальная запись остается в localChangesMap
          }
        } else {
          // Нет локальных изменений - просто применяем данные с сервера
=======
            // Так как мы применили серверную версию, удаляем локальные изменения из карты на отправку
            localChangesMap.remove(localRecord.id);
          } else {
            // Локальная версия новее, ничего не делаем, она останется в `localChangesMap` и будет отправлена на сервер позже.
            print('    -> КОНФЛИКТ: Локальная версия новее для "${localRecord.title}". Она будет отправлена на сервер.');
          }
        } else {
          // Если локальных изменений нет, просто обновляем запись данными с сервера
>>>>>>> master
          await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
              serverChange.toCompanion(SyncStatus.synced),
            );
          print('    -> ОБНОВЛЕНО с сервера: "${serverChange.title}"');
        }
      }
<<<<<<< HEAD
    });

    return localChangesMap.values.toList();
  }

  /// Отправляет на сервер только те локальные изменения, которые "выиграли" слияние.
  Future<void> _pushLocalChanges(List<CategoryTableData> changesToPush) async {
    for (final localChange in changesToPush) {
      if (localChange.syncStatus == SyncStatus.deleted) {
        try {
          await _syncDeleteToServer(localChange.id);
          // Окончательно удаляем "надгробие" из локальной базы
          await _categoryDao.physicallyDeleteCategory(localChange.id, userId: _userId);
          print('    -> ✅ Удаление "${localChange.id}" синхронизировано с сервером.');
        } catch (e) {
          print('    -> ⚠️ Не удалось синхронизировать удаление ID: ${localChange.id}. Повторим позже.');
        }
      } else if (localChange.syncStatus == SyncStatus.local) {
        try {
          final entity = localChange.toModel().toEntity();
          
          // Проверяем, существует ли запись на сервере
          final serverRecord = await _remoteDataSource.getCategoryById(
            serverpod.UuidValue.fromString(entity.id),
          );

          if (serverRecord != null) {
            // Обновляем существующую запись
            await _syncUpdateToServer(entity);
          } else {
            // Создаем новую запись
            await _syncCreateToServer(entity);
          }
          print('    -> ✅ Изменение "${localChange.title}" синхронизировано с сервером.');
        } catch (e) {
          print('    -> ⚠️ Не удалось синхронизировать изменение ID: ${localChange.id}. Повторим позже.');
        }
      }
    }
  }

  // --- REAL-TIME СОБЫТИЯ (остается без изменений) ---
  void _initEventBasedSync() {
    if (_isDisposed) return;
    print('🌊 CategoryRepositoryImpl: _initEventBasedSync для userId: $_userId. Попытка #${_reconnectionAttempt + 1}');
    _eventStreamSubscription?.cancel();
    
    if (_reconnectionAttempt == 0) {
      print('⏱️ Начальная задержка перед первой подпиской WebSocket для userId: $_userId...');
      Future.delayed(const Duration(seconds: 2), () {
        if (_isDisposed) return;
        _subscribeToEvents();
      });
    } else {
      _subscribeToEvents();
    }
  }

  void _scheduleReconnection() {
    if (_isDisposed) return;
    _eventStreamSubscription?.cancel();
    final delaySeconds = min(pow(2, _reconnectionAttempt).toInt(), 60);
    print('⏱️ Следующая попытка подключения через $delaySeconds секунд.');

    Future.delayed(Duration(seconds: delaySeconds), () {
      _reconnectionAttempt++;
      _initEventBasedSync();
    });
  }

  @override
  void dispose() {
    print('🛑 CategoryRepositoryImpl: Уничтожается экземпляр для userId: $_userId. _isDisposed до вызова: $_isDisposed');
    _isDisposed = true;
    _eventStreamSubscription?.cancel();
    print('🛑 CategoryRepositoryImpl: Экземпляр для userId: $_userId УСПЕШНО УНИЧТОЖЕН. _isDisposed после вызова: $_isDisposed');
  }

  Future<void> _handleSyncEvent(serverpod.CategorySyncEvent event) async {
    switch (event.type) {
      case serverpod.SyncEventType.create:
        if (event.category != null && event.category!.userId == _userId) {
          await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
                event.category!.toCompanion(SyncStatus.synced),
              );         
          print('  -> Локально СОЗДАНА категория "${event.category!.title}" по событию с сервера.');
        }
        break;
      case serverpod.SyncEventType.update:
        if (event.category != null && event.category!.userId == _userId) {
          final localCopy = await (_categoryDao.select(_categoryDao.categoryTable)
                ..where((t) => t.id.equals(event.category!.id.toString())))
              .getSingleOrNull();

          if (localCopy != null) {
            if (localCopy.syncStatus == SyncStatus.local) {
              // Есть локальные изменения - сравниваем время
              final serverLastModified = event.category!.lastModified;
              if (serverLastModified != null) {
                if (serverLastModified.isAfter(localCopy.lastModified)) {
                  // Сервер новее - применяем
                  await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
                        event.category!.toCompanion(SyncStatus.synced),
                      );
                  print('  -> КОНФЛИКТ РАЗРЕШЕН (сервер новее): Локально ОБНОВЛЕНА категория "${event.category!.title}" по событию с сервера.');
                } else {
                  // Локальная версия новее - игнорируем
                  print('  -> КОНФЛИКТ (локально новее): Локальные изменения для "${localCopy.title}" имеют приоритет.');
                }
              } else {
                // Нет времени на сервере - приоритет локальным
                print('  -> КОНФЛИКТ (сервер без lastModified): Локальные изменения для "${localCopy.title}" имеют приоритет.');
              }
            } else {
              // Нет локальных изменений - применяем обновление
              await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
                    event.category!.toCompanion(SyncStatus.synced),
                  );
              print('  -> Локально ОБНОВЛЕНА категория "${event.category!.title}" по событию с сервера.');
            }
          } else if (event.category != null) {
            // Записи нет локально - создаем
            await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
                  event.category!.toCompanion(SyncStatus.synced),
                );
            print('  -> Локально НЕ НАЙДЕНА, но получено событие UPDATE. СОЗДАНА категория "${event.category!.title}" по событию с сервера.');
          }
        }
        break;
      case serverpod.SyncEventType.delete:
        if (event.id != null) {
          final localRecord = await (_categoryDao.select(_categoryDao.categoryTable)
                ..where((t) => t.id.equals(event.id!.toString())))
              .getSingleOrNull();

          if (localRecord?.userId == _userId) {
            await _categoryDao.physicallyDeleteCategory(event.id!.toString(), userId: _userId);
            print('  -> Локально УДАЛЕНА категория с ID "${event.id}" по событию с сервера.');
          }
        }
        break;
    }
  }

  // --- CRUD ОПЕРАЦИИ ---
  @override
  Stream<List<CategoryEntity>> watchCategories() {
    return _localDataSource.watchCategories(userId: _userId).map((models) => models.toEntities());
  }

  @override
  Future<String> createCategory(CategoryEntity category) async {
    final categoryWithUser = category.copyWith(userId: _userId);
    final companion = categoryWithUser.toModel().toCompanion().copyWith(
          syncStatus: const Value(SyncStatus.local),
        );

    await _categoryDao.createCategory(companion);
    
    // Запускаем фоновую синхронизацию без ожидания
    syncWithServer().catchError((e) {
      print('⚠️ Фоновая синхронизация после создания не удалась: $e');
    });
    
    return categoryWithUser.id;
  }

=======
    });

    // Возвращаем оставшиеся локальные изменения, которые "выиграли" конфликты и должны быть отправлены на сервер
    return localChangesMap.values.toList();
  }

  /// Отправляет на сервер только те локальные изменения, которые "выиграли" слияние.
  Future<void> _pushLocalChanges(List<CategoryTableData> changesToPush) async {
    for (final localChange in changesToPush) {
      if (localChange.syncStatus == SyncStatus.deleted) {
        try {
          await _syncDeleteToServer(localChange.id);
          // Окончательно удаляем "надгробие" из локальной базы
          await _categoryDao.physicallyDeleteCategory(localChange.id, userId: _userId);
          print('    -> ✅ Удаление "${localChange.id}" синхронизировано с сервером.');
        } catch (e) {
          print('    -> ⚠️ Не удалось синхронизировать удаление ID: ${localChange.id}. Повторим позже.');
        }
      } else if (localChange.syncStatus == SyncStatus.local) {
        try {
          final entity = localChange.toModel().toEntity();
          
          final serverRecord = await _remoteDataSource.getCategoryById(
            serverpod.UuidValue.fromString(entity.id),
          );

          if (serverRecord != null) {
            await _syncUpdateToServer(entity);
          } else {
            await _syncCreateToServer(entity);
          }
          print('    -> ✅ Изменение "${localChange.title}" синхронизировано с сервером.');
        } catch (e) {
          print('    -> ⚠️ Не удалось синхронизировать изменение ID: ${localChange.id}. Повторим позже.');
        }
      }
    }
  }
  
  // --- CRUD ОПЕРАЦИИ (вызывают syncWithServer) ---
  @override
  Stream<List<CategoryEntity>> watchCategories() {
    return _localDataSource.watchCategories(userId: _userId).map((models) => models.toEntities());
  }

  @override
  Future<String> createCategory(CategoryEntity category) async {
    final categoryWithUser = category.copyWith(userId: _userId);
    final companion = categoryWithUser.toModel().toCompanion().copyWith(
          syncStatus: const Value(SyncStatus.local),
        );
    await _categoryDao.createCategory(companion);
    // Запускаем фоновую синхронизацию без ожидания
    syncWithServer().catchError((e) {
      print('⚠️ Фоновая синхронизация после создания не удалась: $e');
    });
    return categoryWithUser.id;
  }

>>>>>>> master
  @override
  Future<bool> updateCategory(CategoryEntity category) async {
    final categoryWithUser = category.copyWith(
      userId: _userId,
      lastModified: DateTime.now().toUtc(), // Обновляем время модификации
    );
    final companion = categoryWithUser.toModel().toCompanion().copyWith(
          syncStatus: const Value(SyncStatus.local),
        );
<<<<<<< HEAD

    final result = await _categoryDao.updateCategory(companion, userId: _userId);
    
=======
    final result = await _categoryDao.updateCategory(companion, userId: _userId);
>>>>>>> master
    // Запускаем фоновую синхронизацию без ожидания
    syncWithServer().catchError((e) {
      print('⚠️ Фоновая синхронизация после обновления не удалась: $e');
    });
<<<<<<< HEAD
    
=======
>>>>>>> master
    return result;
  }

  @override
  Future<bool> deleteCategory(String id) async {
    final result = await _categoryDao.softDeleteCategory(id, userId: _userId);
<<<<<<< HEAD
    
=======
>>>>>>> master
    // Запускаем фоновую синхронизацию без ожидания
    syncWithServer().catchError((e) {
      print('⚠️ Фоновая синхронизация после удаления не удалась: $e');
    });
<<<<<<< HEAD
    
    return result;
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    return _localDataSource.getCategories(userId: _userId).then((models) => models.toEntities());
  }

  @override
  Future<CategoryEntity?> getCategoryById(String id) async {
    try {
      return _localDataSource.getCategoryById(id, userId: _userId).then((model) => model.toEntity());
    } catch (e) {
      return null;
    }
  }

  // --- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ СИНХРОНИЗАЦИИ ---
  Future<void> _syncCreateToServer(CategoryEntity category) async {
    try {
      final serverCategory = category.toServerpodCategory();
      final syncedCategory = await _remoteDataSource.createCategory(serverCategory);
      await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
            syncedCategory.toCompanion(SyncStatus.synced),
          );
      print('    -> ✅ Создание "${category.title}" подтверждено сервером.');
    } catch (e) {
      print('    -> ❌ Ошибка при подтверждении создания "${category.title}": $e');
      rethrow;
    }
  }

  Future<void> _syncUpdateToServer(CategoryEntity category) async {
    try {
      final serverCategory = category.toServerpodCategory();
      await _remoteDataSource.updateCategory(serverCategory);
      await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
            serverCategory.toCompanion(SyncStatus.synced),
          );
      print('    -> ✅ Обновление "${category.title}" подтверждено сервером.');
    } catch (e) {
      print('    -> ❌ Ошибка при подтверждении обновления "${category.title}": $e');
      rethrow;
    }
  }

  Future<void> _syncDeleteToServer(String id) async {
    try {
      await _remoteDataSource.deleteCategory(serverpod.UuidValue.fromString(id));
      print('    -> ✅ Удаление "$id" подтверждено сервером.');
    } catch (e) {
      print('    -> ❌ Ошибка при подтверждении удаления "$id": $e');
      rethrow;
=======
    return result;
  }

  void _initEventBasedSync() {
    if (_isDisposed) return;
    print('🌊 CategoryRepositoryImpl: _initEventBasedSync для userId: $_userId. Попытка #${_reconnectionAttempt + 1}');
    _eventStreamSubscription?.cancel();
    if (_reconnectionAttempt == 0) {
      print('⏱️ Начальная задержка перед первой подпиской WebSocket для userId: $_userId...');
      Future.delayed(const Duration(seconds: 2), () {
        if (_isDisposed) return;
        _subscribeToEvents();
      });
    } else {
      _subscribeToEvents();
>>>>>>> master
    }
  }

  void _subscribeToEvents() {
    if (_isDisposed) return;
    print('🎧 CategoryRepositoryImpl: Выполняется подписка на события для userId: $_userId (попытка: ${_reconnectionAttempt})');
<<<<<<< HEAD

=======
>>>>>>> master
    _eventStreamSubscription = _remoteDataSource.watchEvents().listen(
      (event) {
        print('⚡️ Получено событие с сервера: ${event.type.name} (для userId: $_userId)');
        if (_reconnectionAttempt > 0) {
          print('👍 Соединение с real-time сервером восстановлено для userId: $_userId!');
          _reconnectionAttempt = 0;
        }
        _handleSyncEvent(event);
      },
      onError: (error) {
        print('❌ Ошибка стрима событий для userId: $_userId: $error. Планируем переподключение...');
        _scheduleReconnection();
      },
      onDone: () {
        print('🔌 Стрим событий был закрыт (onDone) для userId: $_userId. Планируем переподключение...');
        _scheduleReconnection();
      },
      cancelOnError: true,
    );
  }

  void _scheduleReconnection() {
    if (_isDisposed) return;
    _eventStreamSubscription?.cancel();
    if (_reconnectionAttempt >= _maxReconnectionAttempts) {
      print('🚫 Достигнуто максимальное количество попыток переподключения ($_maxReconnectionAttempts). Попытки прекращены.');
      return;
    }
    final delaySeconds = min(pow(2, _reconnectionAttempt).toInt(), 20);
    print('⏱️ Следующая попытка подключения через $delaySeconds секунд.');
    Future.delayed(Duration(seconds: delaySeconds), () {
      _reconnectionAttempt++;
      _initEventBasedSync();
    });
  }

  Future<void> _handleSyncEvent(serverpod.CategorySyncEvent event) async {
    switch (event.type) {
      case serverpod.SyncEventType.create:
        if (event.category != null && event.category!.userId == _userId) {
          await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
                event.category!.toCompanion(SyncStatus.synced),
              );
          print('  -> (Real-time) СОЗДАНА: "${event.category!.title}"');
        }
        break;
      case serverpod.SyncEventType.update:
        if (event.category != null && event.category!.userId == _userId) {
          final localCopy = await (_categoryDao.select(_categoryDao.categoryTable)..where((t) => t.id.equals(event.category!.id.toString()))).getSingleOrNull();
          if (localCopy != null) {
            if (localCopy.syncStatus == SyncStatus.local) {
              final serverLastModified = event.category!.lastModified;
              if (serverLastModified != null) {
                if (serverLastModified.isAfter(localCopy.lastModified)) {
                  await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
                        event.category!.toCompanion(SyncStatus.synced),
                      );
                  print('  -> (Real-time) КОНФЛИКТ РАЗРЕШЕН (сервер новее): "${event.category!.title}"');
                } else {
                  print('  -> (Real-time) КОНФЛИКТ (локально новее): "${localCopy.title}". Игнорируем.');
                }
              } else {
                print('  -> (Real-time) КОНФЛИТК (сервер без lastModified): "${localCopy.title}". Игнорируем.');
              }
            } else {
              await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
                    event.category!.toCompanion(SyncStatus.synced),
                  );
              print('  -> (Real-time) ОБНОВЛЕНА: "${event.category!.title}"');
            }
          } else if (event.category != null) {
            await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
                  event.category!.toCompanion(SyncStatus.synced),
                );
            print('  -> (Real-time) UPDATE для несуществующей локально. СОЗДАНА: "${event.category!.title}"');
          }
        }
        break;
      case serverpod.SyncEventType.delete:
        if (event.id != null) {
          final localRecord = await (_categoryDao.select(_categoryDao.categoryTable)..where((t) => t.id.equals(event.id!.toString()))).getSingleOrNull();
          if (localRecord?.userId == _userId) {
            await _categoryDao.physicallyDeleteCategory(event.id!.toString(), userId: _userId);
            print('  -> (Real-time) УДАЛЕНА ID: "${event.id}"');
          }
        }
        break;
    }
  }

  @override
  void dispose() {
    print('🛑 CategoryRepositoryImpl: Уничтожается экземпляр для userId: $_userId. _isDisposed до вызова: $_isDisposed');
    _isDisposed = true;
    _eventStreamSubscription?.cancel();
    print('🛑 CategoryRepositoryImpl: Экземпляр для userId: $_userId УСПЕШНО УНИЧТОЖЕН. _isDisposed после вызова: $_isDisposed');
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    return _localDataSource.getCategories(userId: _userId).then((models) => models.toEntities());
  }

  @override
  Future<CategoryEntity?> getCategoryById(String id) async {
    try {
      return _localDataSource.getCategoryById(id, userId: _userId).then((model) => model.toEntity());
    } catch (e) {
      return null;
    }
  }

  Future<void> _syncCreateToServer(CategoryEntity category) async {
    try {
      final serverCategory = category.toServerpodCategory();
      final syncedCategory = await _remoteDataSource.createCategory(serverCategory);
      await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
            syncedCategory.toCompanion(SyncStatus.synced),
          );
      print('    -> ✅ Создание "${category.title}" подтверждено сервером.');
    } catch (e) {
      print('    -> ❌ Ошибка при подтверждении создания "${category.title}": $e');
      rethrow;
    }
  }

  Future<void> _syncUpdateToServer(CategoryEntity category) async {
    try {
      final serverCategory = category.toServerpodCategory();
      await _remoteDataSource.updateCategory(serverCategory);
      await _categoryDao.db.into(_categoryDao.categoryTable).insertOnConflictUpdate(
            serverCategory.toCompanion(SyncStatus.synced),
          );
      print('    -> ✅ Обновление "${category.title}" подтверждено сервером.');
    } catch (e) {
      print('    -> ❌ Ошибка при подтверждении обновления "${category.title}": $e');
      rethrow;
    }
  }

  Future<void> _syncDeleteToServer(String id) async {
    try {
      await _remoteDataSource.deleteCategory(serverpod.UuidValue.fromString(id));
      print('    -> ✅ Удаление "$id" подтверждено сервером.');
    } catch (e) {
      print('    -> ❌ Ошибка при подтверждении удаления "$id": $e');
      rethrow;
    }
  }
}

// --- РАСШИРЕНИЯ ---
extension on CategoryEntity {
  serverpod.Category toServerpodCategory() => serverpod.Category(
        id: serverpod.UuidValue.fromString(id),
        title: title,
        lastModified: lastModified,
        userId: userId,
      );
}

extension on serverpod.Category {
  CategoryTableCompanion toCompanion(SyncStatus status) => CategoryTableCompanion(
        id: Value(id.toString()),
        title: Value(title),
        lastModified: Value(lastModified ?? DateTime.now().toUtc()),
        userId: Value(userId),
        syncStatus: Value(status),
      );
}