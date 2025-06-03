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
import '../datasources/remote/interfaces/category_remote_datasource_service.dart';
import '../models/extensions/category_model_extension.dart';

/// Offline-first Repository для категорий с автоматической синхронизацией
class CategoryRepositoryImpl implements ICategoryRepository {
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
      (serverCategories) => _performSync(serverCategories),
      onError: (error) { /* Обработка ошибок стрима */ },
    );
  }

  /// Основная логика синхронизации: полная замена данных с сервера.
  Future<void> _performSync(List<serverpod.Category> serverCategories) async {
    try {
      await _categoryDao.db.transaction(() async {
        // 1. Полностью очищаем локальную таблицу от НЕУДАЛЕННЫХ записей.
        // Это предотвращает восстановление локально удаленных, но еще не синхронизированных записей.
        await (_categoryDao.delete(_categoryDao.categoryTable)
              ..where((t) => t.deleted.equals(false)))
            .go();
        
        // 2. Вставляем все категории, полученные с сервера
        final companions = serverCategories
            .where((c) => c.deleted == false) // Игнорируем удаленные на сервере
            .map((c) => CategoryTableCompanion.insert(
                  id: Value(c.id.toString()),
                  title: c.title,
                  lastModified: c.lastModified,
                  syncStatus: SyncStatus.synced, // Данные с сервера всегда синхронизированы
                  deleted: const Value(false),
                ))
            .toList();

        if (companions.isNotEmpty) {
          await _categoryDao.insertCategories(companions);
        }
      });
    } catch (e) {
      // Обработка ошибок синхронизации
    }
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    // UI слушает только локальную базу и получает только НЕ удаленные записи.
    return _localDataSource
        .watchCategories()
        .map((models) => models.toEntities());
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
      // Обработка ошибки фоновой синхронизации
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
      // Обработка ошибки фоновой синхронизации
    });

    return result;
  }

  @override
  Future<bool> deleteCategory(String id) async {
    // "Мягкое удаление": помечаем запись как удаленную и ставим статус 'local'
    final companion = CategoryTableCompanion(
      id: Value(id),
      deleted: const Value(true),
      lastModified: Value(DateTime.now().toUtc()),
      syncStatus: const Value(SyncStatus.local),
    );
    
    // Используем update для установки флагов
    final result = await _categoryDao.updateCategory(companion);

    // Пытаемся синхронизировать удаление с сервером
    _syncDeleteToServer(id).catchError((error) {
       // Обработка ошибки фоновой синхронизации
    });

    return result;
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
    // После успешной синхронизации сервер пришлет обновление через стрим,
    // и _performSync обновит статус локальной записи на 'synced'.
    await _remoteDataSource.createCategory(serverpodCategory);
  }

  Future<void> _syncUpdateToServer(CategoryEntity category) async {
    final serverpodCategory = serverpod.Category(
      id: serverpod.UuidValue.fromString(category.id),
      title: category.title,
      lastModified: category.lastModified,
      deleted: false,
    );
    await _remoteDataSource.updateCategory(serverpodCategory);
  }

  Future<void> _syncDeleteToServer(String id) async {
    // В идеале, серверный метод deleteCategory тоже должен делать soft delete.
    // Пока он делает hard delete, что тоже будет работать с нашей логикой.
    await _remoteDataSource.deleteCategory(serverpod.UuidValue.fromString(id));
  }

  @override
  Future<void> syncWithServer() async {
    try {
      final serverCategories = await _remoteDataSource.getCategories();
      await _performSync(serverCategories);
    } catch (e) {
      rethrow;
    }
  }
  
}