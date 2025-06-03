// G:/Projects/Flutter/serverpod/sync1/sync1_flutter/lib/features/home/data/repositories/category_repository_impl.dart
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:sync1_client/sync1_client.dart' as serverpod;

import '../../../../core/database/local/database.dart';
import '../../domain/entities/category/category.dart';
import '../../domain/entities/extensions/category_entity_extension.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local/interfaces/category_local_datasource_service.dart';
import '../datasources/local/sources/category_local_data_source.dart';
import '../datasources/local/tables/category_table.dart';
import '../datasources/remote/interfaces/category_remote_datasource_service.dart';
import '../models/extensions/category_model_extension.dart';

/// Offline-first Repository для категорий с автоматической синхронизацией
class CategoryRepositoryImpl implements ICategoryRepository {
  final ICategoryLocalDataSource _localDataSource;
  final ICategoryRemoteDataSource _remoteDataSource;
  StreamSubscription? _serverStreamSubscription;

  CategoryRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  ) {
    // Автоматически запускаем синхронизацию при создании репозитория
    _initServerSync();
  }

  void _initServerSync() {
    if (_serverStreamSubscription != null) return;

    _serverStreamSubscription = _remoteDataSource.watchCategories().listen(
      (serverCategories) {
        _performSync(serverCategories);
      },
      onError: (error) {
        // Здесь можно добавить более сложную обработку ошибок
      },
      onDone: () {
        _serverStreamSubscription = null;
      },
    );
  }

  /// Основная логика синхронизации. Стратегия: "сервер - единственный источник правды".
  Future<void> _performSync(List<serverpod.Category> serverCategories) async {
    try {
      // Это простая и надежная стратегия: локальная база полностью отражает состояние сервера.
      final categoryDao = (_localDataSource as CategoryLocalDataSource).categoryDao;

      await categoryDao.db.transaction(() async {
        // 1. Полностью очищаем локальную таблицу
        await categoryDao.deleteAllCategories();
        
        // 2. Вставляем все категории, полученные с сервера
        final companions = serverCategories.map((c) => 
            CategoryTableCompanion.insert(
              id: Value(c.id.toString()),
              title: c.title,
              lastModified: c.lastModified,
              syncStatus: SyncStatus.synced, // Серверные данные всегда синхронизированы
            )
        ).toList();

        if (companions.isNotEmpty) {
          await categoryDao.insertCategories(companions);
        }
      });

    } catch (e) {
      // Обработка ошибок синхронизации
    }
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    // UI по-прежнему слушает только локальную базу данных для максимальной отзывчивости
    return _localDataSource.watchCategories().map(
      (models) => models.toEntities(),
    );
  }

  @override
  Future<String> createCategory(CategoryEntity category) async {
    // 1. Оптимистично создаем локально
    final localId = await _localDataSource.createCategory(category.toModel());
    
    // 2. Отправляем на сервер. Изменения придут обратно через stream.
    _syncCreateToServer(category).catchError((error) {
      // Здесь можно добавить логику обработки ошибок, например, откат локального создания
    });
    
    return localId;
  }
  
  // ... другие методы CRUD (update, delete) остаются такими же,
  // они так же оптимистично обновляют локальные данные и отправляют изменения на сервер.

  @override
  void dispose() {
    _serverStreamSubscription?.cancel();
    _serverStreamSubscription = null;
  }
  
  // Остальные методы (getCategories, getCategoryById, update, delete, _sync...) остаются без изменений.
  
  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      final localCategories = await _localDataSource.getCategories();
      return localCategories.toEntities();
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<CategoryEntity> getCategoryById(String id) async {
    try {
      final model = await _localDataSource.getCategoryById(id);
      return model.toEntity();
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<bool> updateCategory(CategoryEntity category) async {
    final localResult = await _localDataSource.updateCategory(category.toModel());
    _syncUpdateToServer(category).catchError((error) {
      // Обработка ошибок
    });
    return localResult;
  }

  @override
  Future<bool> deleteCategory(String id) async {
    final localResult = await _localDataSource.deleteCategory(id);
    _syncDeleteToServer(id).catchError((error) {
      // Обработка ошибок
    });
    return localResult;
  }

  Future<void> _syncCreateToServer(CategoryEntity category) async {
    try {
      final serverpodCategory = serverpod.Category(
        id: serverpod.UuidValue.fromString(category.id),
        title: category.title,
        lastModified: category.lastModified,
      );
      await _remoteDataSource.createCategory(serverpodCategory);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncUpdateToServer(CategoryEntity category) async {
    try {
      final serverpodCategory = serverpod.Category(
        id: serverpod.UuidValue.fromString(category.id),
        title: category.title,
        lastModified: category.lastModified,
      );
      await _remoteDataSource.updateCategory(serverpodCategory);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncDeleteToServer(String id) async {
    try {
      final uuidValue = serverpod.UuidValue.fromString(id);
      await _remoteDataSource.deleteCategory(uuidValue);
    } catch (e) {
      rethrow;
    }
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