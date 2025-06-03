// lib/features/home/data/repositories/category_repository_impl.dart

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:sync1/features/home/data/datasources/local/tables/extensions/category_table_extension.dart';
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
import '../datasources/remote/interfaces/category_remote_datasource_service.dart';
import '../models/extensions/category_model_extension.dart';

/// Offline-first Repository для категорий с дифференциальной синхронизацией
class CategoryRepositoryImpl implements ICategoryRepository {
  static const String _entityType = 'categories';

  final ICategoryLocalDataSource _localDataSource;
  final ICategoryRemoteDataSource _remoteDataSource;
  final SyncMetadataDao _syncMetadataDao;
  StreamSubscription? _serverStreamSubscription;

  // Получаем прямой доступ к DAO для управления статусами
  final CategoryDao _categoryDao;

  CategoryRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._syncMetadataDao,
  ) : _categoryDao = (_localDataSource as CategoryLocalDataSource).categoryDao {
    // Автоматически запускаем синхронизацию при создании репозитория
    _initServerSync();
  }

  void _initServerSync() {
    if (_serverStreamSubscription != null) return;
    _serverStreamSubscription = _remoteDataSource.watchCategories().listen(
      (serverCategories) => _performDifferentialSync(serverCategories),
      onError: (error) {
        print('❌ Ошибка серверного стрима: $error');
      },
    );
  }

  /// Дифференциальная синхронизация: обрабатывает только изменения
  Future<void> _performDifferentialSync(
    List<serverpod.Category> serverCategories,
  ) async {
    try {
      print(
        '🔄 Начинаем дифференциальную синхронизацию (${serverCategories.length} записей с сервера)',
      );

      await _categoryDao.db.transaction(() async {
        for (final serverCategory in serverCategories) {
          await _processSingleCategoryUpdate(serverCategory);
        }

        // Обновляем время последней синхронизации
        await _syncMetadataDao.updateLastSyncTimestamp(
          _entityType,
          DateTime.now().toUtc(),
        );
      });

      print('✅ Дифференциальная синхронизация завершена');
    } catch (e) {
      print('❌ Ошибка дифференциальной синхронизации: $e');
    }
  }

 /// Обрабатывает обновление одной категории с сервера
Future<void> _processSingleCategoryUpdate(serverpod.Category serverCategory) async {
  final categoryId = serverCategory.id.toString();
  
  // Получаем текущую локальную запись (если есть) - используем метод DAO
  CategoryTableData? localCategory;
  try {
    localCategory = await _categoryDao.getCategoryById(categoryId);
  } catch (e) {
    // Если запись не найдена, getCategoryById выбросит исключение
    localCategory = null;
  }

  if (localCategory == null) {
    // Новая запись с сервера - просто добавляем
    await _insertServerCategory(serverCategory);
    print('➕ Добавлена новая категория: ${serverCategory.title}');
  } else {
    // Существующая запись - нужно решить конфликт
    await _resolveConflict(localCategory, serverCategory);
  }
}

  /// Вставляет новую категорию с сервера
Future<void> _insertServerCategory(serverpod.Category serverCategory) async {
  final companion = CategoryTableCompanion.insert(
    id: Value(serverCategory.id.toString()),
    title: serverCategory.title,
    // Используем текущее время, если сервер не передал lastModified
    lastModified: serverCategory.lastModified ?? DateTime.now().toUtc(),
    deleted: Value(serverCategory.deleted),
    syncStatus: SyncStatus.synced,
  );

  await _categoryDao.db.into(_categoryDao.categoryTable).insert(companion);
}

  /// Разрешает конфликт между локальной и серверной записью
Future<void> _resolveConflict(
  CategoryTableData localCategory,
  serverpod.Category serverCategory,
) async {
  // Используем текущее время, если сервер не передал lastModified
  final serverTime = serverCategory.lastModified ?? DateTime.now().toUtc();
  final localTime = localCategory.lastModified;

  // Стратегия разрешения конфликтов: "server wins" + учет локальных изменений
  if (localCategory.syncStatus == SyncStatus.local) {
    // Локальная запись была изменена и еще не синхронизирована
    if (serverTime.isAfter(localTime)) {
      // Сервер новее - принимаем серверную версию, но помечаем конфликт
      await _updateToServerVersion(
        localCategory.id,
        serverCategory,
        isConflict: true,
      );
      print('⚠️ Конфликт разрешен в пользу сервера: ${serverCategory.title}');
    } else {
      // Локальная версия новее или равна - оставляем локальную, но нужно будет синхронизировать
      print('📝 Локальная версия новее, оставляем: ${localCategory.title}');
      // Запланируем повторную отправку на сервер
      _retryLocalSync(localCategory);
    }
  } else {
    // Локальная запись синхронизирована - просто обновляем до серверной версии
    if (serverTime.isAfter(localTime)) {
      await _updateToServerVersion(localCategory.id, serverCategory);
      print('🔄 Обновлено с сервера: ${serverCategory.title}');
    }
    // Если серверная версия старше или равна, ничего не делаем
  }
}

  /// Обновляет локальную запись до серверной версии
Future<void> _updateToServerVersion(
  String categoryId,
  serverpod.Category serverCategory, {
  bool isConflict = false,
}) async {
  final companion = CategoryTableCompanion(
    id: Value(categoryId),
    title: Value(serverCategory.title),
    // Используем текущее время, если сервер не передал lastModified
    lastModified: Value(serverCategory.lastModified ?? DateTime.now().toUtc()),
    deleted: Value(serverCategory.deleted),
    syncStatus: Value(isConflict ? SyncStatus.conflict : SyncStatus.synced),
  );

  await _categoryDao.updateCategory(companion);
}

  /// Планирует повторную синхронизацию локальной записи
  Future<void> _retryLocalSync(CategoryTableData localCategory) async {
    // В этой реализации просто пытаемся отправить на сервер
    try {
      final entity = localCategory.toModel().toEntity();
      if (localCategory.deleted) {
        await _syncDeleteToServer(localCategory.id);
      } else {
        await _syncUpdateToServer(entity);
      }
    } catch (e) {
      print('❌ Ошибка повторной синхронизации: $e');
      // В реальном приложении здесь можно было бы добавить в очередь повторных попыток
    }
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    // UI слушает только локальную базу и получает только НЕ удаленные записи.
    return _localDataSource.watchCategories().map(
      (models) => models.toEntities(),
    );
  }

  @override
  Future<String> createCategory(CategoryEntity category) async {
    // 1. Готовим Companion с правильным статусом
    final companion = CategoryTableCompanion.insert(
      id: Value(category.id),
      title: category.title,
      lastModified: category.lastModified,
      // Устанавливаем статус 'local', чтобы запись ушла на сервер
      syncStatus: SyncStatus.local,
    );

    // 2. Оптимистично создаем запись локально
    await _categoryDao.createCategory(companion);

    // 3. Пытаемся синхронизировать с сервером в фоне
    _syncCreateToServer(category).catchError((error) {
      print('❌ Ошибка синхронизации создания: $error');
    });

    return category.id;
  }

  @override
  Future<bool> updateCategory(CategoryEntity category) async {
    // 1. Готовим Companion с правильным статусом
    final companion = category.toModel().toCompanion().copyWith(
      lastModified: Value(category.lastModified),
      // Устанавливаем статус 'local' при любом локальном изменении
      syncStatus: const Value(SyncStatus.local),
    );

    // 2. Оптимистично обновляем локально
    final result = await _categoryDao.updateCategory(companion);

    // 3. Пытаемся синхронизировать с сервером в фоне
    _syncUpdateToServer(category).catchError((error) {
      print('❌ Ошибка синхронизации обновления: $error');
    });

    return result;
  }

  @override
Future<bool> deleteCategory(String id) async {
  try {
    // 1. Получаем существующую запись
    final existingCategory = await _categoryDao.getCategoryById(id);
    
    // 2. "Мягкое удаление": помечаем запись как удаленную и ставим статус 'local'
    final companion = CategoryTableCompanion(
      id: Value(id),
      title: Value(existingCategory.title), // Сохраняем существующий title
      lastModified: Value(DateTime.now().toUtc()),
      deleted: const Value(true),
      syncStatus: const Value(SyncStatus.local),
    );
    
    // 3. Используем update для установки флагов
    final result = await _categoryDao.updateCategory(companion);

    // 4. Пытаемся синхронизировать удаление с сервером
    _syncDeleteToServer(id).catchError((error) {
       print('❌ Ошибка синхронизации удаления: $error');
    });

    return result;
  } catch (e) {
    print('❌ Ошибка при удалении категории: $e');
    return false;
  }
}

  @override
  Future<void> syncWithServer() async {
    try {
      print('🔄 Запуск полной синхронизации с сервером...');

      // Получаем время последней синхронизации
      final lastSync = await _syncMetadataDao.getLastSyncTimestamp(_entityType);

      // Получаем изменения с сервера с указанного времени
      final serverCategories = await _getServerChangesSince(lastSync);

      if (serverCategories.isNotEmpty) {
        await _performDifferentialSync(serverCategories);
      }

      // Синхронизируем локальные изменения с сервером
      await _syncLocalChangesToServer();

      print('✅ Полная синхронизация завершена');
    } catch (e) {
      print('❌ Ошибка полной синхронизации: $e');
      rethrow;
    }
  }

  /// Получает изменения с сервера с указанного времени
  Future<List<serverpod.Category>> _getServerChangesSince(
    DateTime? since,
  ) async {
    // Предполагаем, что на сервере есть метод getCategoriesSince
    // Пока используем обычный getCategories, но в идеале нужен дифференциальный метод
    return await _remoteDataSource.getCategories();
  }

  /// Синхронизирует все локальные несинхронизированные изменения с сервером
Future<void> _syncLocalChangesToServer() async {
  // Получаем все записи со статусом 'local' или 'conflict' - конвертируем enum в строки
  // final localChanges = await (_categoryDao.select(_categoryDao.categoryTable)
  final localChanges = await (_categoryDao.db.select(_categoryDao.categoryTable)

        ..where((t) => t.syncStatus.isIn([
          SyncStatus.local.name, 
          SyncStatus.conflict.name
        ])))
      .get();

  for (final localChange in localChanges) {
    try {
      if (localChange.deleted) {
        await _syncDeleteToServer(localChange.id);
      } else {
        // Используем extension для конвертации в entity
        final entity = localChange.toModel().toEntity();
        await _syncUpdateToServer(entity);
      }
      
      // После успешной синхронизации обновляем статус
      await _categoryDao.updateCategory(CategoryTableCompanion(
        id: Value(localChange.id),
        syncStatus: const Value(SyncStatus.synced),
      ));
      
    } catch (e) {
      print('❌ Ошибка синхронизации записи ${localChange.id}: $e');
      // Продолжаем с другими записями
    }
  }
}

  @override
  void dispose() {
    _serverStreamSubscription?.cancel();
    _serverStreamSubscription = null;
  }

  // Методы для получения данных работают как раньше, через _localDataSource
  @override
  Future<List<CategoryEntity>> getCategories() async =>
      _localDataSource.getCategories().then((models) => models.toEntities());

  @override
  Future<CategoryEntity> getCategoryById(String id) async =>
      _localDataSource.getCategoryById(id).then((model) => model.toEntity());

  // Приватные методы для общения с сервером
  Future<void> _syncCreateToServer(CategoryEntity category) async {
    final serverpodCategory = serverpod.Category(
      id: serverpod.UuidValue.fromString(category.id),
      title: category.title,
      lastModified: category.lastModified,
      deleted: false,
    );

    await _remoteDataSource.createCategory(serverpodCategory);
    print('📤 Создание отправлено на сервер: ${category.title}');
  }

  Future<void> _syncUpdateToServer(CategoryEntity category) async {
    final serverpodCategory = serverpod.Category(
      id: serverpod.UuidValue.fromString(category.id),
      title: category.title,
      lastModified: category.lastModified,
      deleted: false,
    );

    await _remoteDataSource.updateCategory(serverpodCategory);
    print('📤 Обновление отправлено на сервер: ${category.title}');
  }

  Future<void> _syncDeleteToServer(String id) async {
    await _remoteDataSource.deleteCategory(serverpod.UuidValue.fromString(id));
    print('📤 Удаление отправлено на сервер: $id');
  }
}
