// lib/features/home/data/repositories/category_repository_impl.dart

import 'dart:async';
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
import '../datasources/local/tables/category_table.dart';
import '../datasources/remote/interfaces/category_remote_datasource_service.dart';
import 'base_sync_repository.dart';

class CategoryRepositoryImpl extends BaseSyncRepository<
        CategoryEntity,
        CategoryTableCompanion,
        CategoryTableData,
        serverpod.Category,
        serverpod.CategorySyncEvent>
    implements ICategoryRepository {

  CategoryRepositoryImpl({
    required ICategoryRemoteDataSource remoteDataSource,
    required SyncMetadataDao syncMetadataDao,
    required CategoryDao categoryDao,
    required int userId,
  }) : super(
            remoteDataSource: remoteDataSource,
            syncMetadataDao: syncMetadataDao,
            localDao: categoryDao,
            db: categoryDao.db,
            userId: userId);

  // --- Реализация методов из ICategoryRepository ---

  @override
  Future<String> createCategory(CategoryEntity entity) async {
    final companion = entityToCompanion(entity, SyncStatus.local);
    await (localDao as CategoryDao).createCategory(companion);
    syncWithServer().ignore();
    return entity.id;
  }

  @override
  Future<bool> updateCategory(CategoryEntity entity) async {
    final companion = entityToCompanion(entity, SyncStatus.local)
        .copyWith(lastModified: Value(DateTime.now().toUtc()));
    final result = await (localDao as CategoryDao).updateCategory(companion, userId: userId);
    syncWithServer().ignore();
    return result;
  }

  @override
  Future<bool> deleteCategory(String id) async {
    final result = await (localDao as CategoryDao).softDeleteCategory(id, userId: userId);
    syncWithServer().ignore();
    return result;
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final data = await (localDao as CategoryDao).getCategories(userId: userId);
    return localDataListToEntities(data);
  }

  @override
  Future<CategoryEntity?> getCategoryById(String id) async {
    try {
      final data = await (localDao as CategoryDao).getCategoryById(id, userId: userId);
      return localDataToEntity(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    return (localDao as CategoryDao).watchCategories(userId: userId).map(localDataListToEntities);
  }

  // --- Реализация абстрактных методов из BaseSyncRepository ---

  @override
  String get entityType => 'categories_user_$userId';

  @override
  CategoryEntity localDataToEntity(CategoryTableData data) => data.toModel().toEntity();

  @override
  List<CategoryEntity> localDataListToEntities(List<CategoryTableData> dataList) =>
      dataList.map((e) => e.toModel().toEntity()).toList();

  @override
  CategoryTableCompanion entityToCompanion(CategoryEntity entity, SyncStatus status) =>
      entity.toModel().toCompanion().copyWith(syncStatus: Value(status));

  @override
  String getLocalDataId(CategoryTableData data) => data.id;

  @override
  SyncStatus getLocalDataSyncStatus(CategoryTableData data) => data.syncStatus;

  @override
  DateTime getLocalDataLastModified(CategoryTableData data) => data.lastModified;

  @override
  Future<List<serverpod.Category>> fetchServerChanges(DateTime? since) {
    return (remoteDataSource as ICategoryRemoteDataSource).getCategoriesSince(since);
  }

  @override
  Future<List<CategoryTableData>> getLocalChangesForPush() async {
    final query = (localDao as CategoryDao)
        .select((localDao as CategoryDao).categoryTable)
        .where((t) =>
            (t.syncStatus.equals(SyncStatus.synced.name).not()) &
            t.userId.equals(userId));
    return await query.get();
  }

  @override
  Stream<serverpod.CategorySyncEvent> watchRemoteEvents() {
    return (remoteDataSource as ICategoryRemoteDataSource).watchEvents();
  }

  @override
  Future<void> pushLocalChanges(List<CategoryTableData> changesToPush) async {
    final categoryDao = (localDao as CategoryDao);
    final remote = (remoteDataSource as ICategoryRemoteDataSource);

    for (final localChange in changesToPush) {
      final localId = getLocalDataId(localChange);
      final localStatus = getLocalDataSyncStatus(localChange);

      if (localStatus == SyncStatus.deleted) {
        try {
          await remote.deleteCategory(serverpod.UuidValue.fromString(localId));
          await categoryDao.physicallyDeleteCategory(localId, userId: userId);
        } catch (e) {
          // log error
        }
      } else if (localStatus == SyncStatus.local) {
        try {
          final entity = localDataToEntity(localChange);
          final serverCategory = entity.toServerpodCategory();

          final serverRecord = await remote.getCategoryById(serverpod.UuidValue.fromString(entity.id));

          if (serverRecord != null && !serverRecord.isDeleted) {
            await remote.updateCategory(serverCategory);
          } else {
            await remote.createCategory(serverCategory);
          }
          
          await db.into(categoryDao.categoryTable).insertOnConflictUpdate(
                serverCategory.toCompanion(SyncStatus.synced),
              );

        } catch (e) {
          // log error
        }
      }
    }
  }

  @override
  Future<List<CategoryTableData>> reconcileChanges(List<serverpod.Category> serverChanges) async {
    final categoryDao = (localDao as CategoryDao);
    final allLocalChanges = await getLocalChangesForPush();
    final localChangesMap = {for (var c in allLocalChanges) getLocalDataId(c): c};

    await db.transaction(() async {
      for (final serverChange in serverChanges) {
        if (serverChange.userId != userId) continue;

        final serverId = serverChange.id.toString();
        final localRecord = await (categoryDao.select(categoryDao.categoryTable)
              ..where((t) => t.id.equals(serverId)))
            .getSingleOrNull();

        if (localRecord == null) {
          if (!serverChange.isDeleted) {
            await db.into(categoryDao.categoryTable).insertOnConflictUpdate(
                  serverChange.toCompanion(SyncStatus.synced),
                );
          }
          continue;
        }

        final serverTime = serverChange.lastModified ?? DateTime.fromMicrosecondsSinceEpoch(0);
        final localTime = getLocalDataLastModified(localRecord);
        final localStatus = getLocalDataSyncStatus(localRecord);

        if (serverChange.isDeleted) {
          if (localTime.isAfter(serverTime) && localStatus == SyncStatus.local) {
            // local wins
          } else {
            await categoryDao.physicallyDeleteCategory(serverId, userId: userId);
            localChangesMap.remove(serverId);
          }
        } else {
          if (localStatus == SyncStatus.local || localStatus == SyncStatus.deleted) {
            if (serverTime.isAfter(localTime)) {
              await db.into(categoryDao.categoryTable).insertOnConflictUpdate(
                    serverChange.toCompanion(SyncStatus.synced),
                  );
              localChangesMap.remove(serverId);
            }
          } else {
            await db.into(categoryDao.categoryTable).insertOnConflictUpdate(
                  serverChange.toCompanion(SyncStatus.synced),
                );
          }
        }
      }
    });

    return localChangesMap.values.toList();
  }

  @override
  Future<void> handleSyncEvent(serverpod.CategorySyncEvent event) async {
    final categoryDao = (localDao as CategoryDao);

    try {
      switch (event.type) {
        case serverpod.SyncEventType.create:
          if (event.category != null && event.category!.userId == userId) {
            await db.into(categoryDao.categoryTable).insertOnConflictUpdate(
                  event.category!.toCompanion(SyncStatus.synced),
                );
          }
          break;

        case serverpod.SyncEventType.update:
          if (event.category != null && event.category!.userId == userId) {
            final eventCategory = event.category!;
            final localCopy = await (categoryDao.select(categoryDao.categoryTable)
                  ..where((t) => t.id.equals(eventCategory.id.toString()))).getSingleOrNull();

            if (localCopy != null && getLocalDataSyncStatus(localCopy) == SyncStatus.local) {
              final serverLastModified = eventCategory.lastModified;
              if (serverLastModified != null &&
                  serverLastModified.isAfter(getLocalDataLastModified(localCopy))) {
                await db.into(categoryDao.categoryTable).insertOnConflictUpdate(
                      eventCategory.toCompanion(SyncStatus.synced),
                    );
              }
            } else {
              await db.into(categoryDao.categoryTable).insertOnConflictUpdate(
                    eventCategory.toCompanion(SyncStatus.synced),
                  );
            }
          }
          break;

        case serverpod.SyncEventType.delete:
          if (event.id != null) {
            final deleteId = event.id!.toString();
            final localRecord = await (categoryDao.select(categoryDao.categoryTable)
                  ..where((t) => t.id.equals(deleteId))).getSingleOrNull();

            if (localRecord?.userId == userId) {
              final serverLastModified = event.category?.lastModified;
              if (serverLastModified != null &&
                  getLocalDataSyncStatus(localRecord!) == SyncStatus.local &&
                  getLocalDataLastModified(localRecord).isAfter(serverLastModified)) {
                // local wins
              } else {
                await categoryDao.physicallyDeleteCategory(deleteId, userId: userId);
              }
            }
          }
          break;
      }
    } catch (e) {
      // log error
    }
  }
}

// --- Вспомогательные extension-методы ---

extension on CategoryEntity {
  serverpod.Category toServerpodCategory() => serverpod.Category(
        id: serverpod.UuidValue.fromString(id),
        title: title,
        lastModified: lastModified,
        userId: userId,
        isDeleted: false,
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