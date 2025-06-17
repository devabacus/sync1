import 'package:drift/drift.dart';

import '../../../../../../../core/database/local/database.dart';
import '../../tables/sync_metadata_table.dart';

part 'sync_metadata_dao.g.dart';

// Опционально: Константы для типов сущностей
class SyncEntityTypes {
  static const String categories = 'categories';
  static const String users = 'users';
  // и т.д.
}

/// Data Access Object для работы с таблицей SyncMetadata.
@DriftAccessor(tables: [SyncMetadata])
class SyncMetadataDao extends DatabaseAccessor<AppDatabase> with _$SyncMetadataDaoMixin {
  SyncMetadataDao(super.db);

  /// Получает время последней успешной синхронизации для указанной сущности и пользователя.
  /// Возвращает null, если метаданные для этой сущности еще не существуют.
  Future<DateTime?> getLastSyncTimestamp(String entityType, {required int userId}) async {
    final entry = await (select(syncMetadata)
          ..where((t) => t.entityType.equals(entityType) & t.userId.equals(userId)))
        .getSingleOrNull();
    return entry?.lastSyncTimestamp;
  }

  /// Обновляет время последней успешной синхронизации для указанной сущности и пользователя.
  /// Если запись для сущности не существует, она будет создана.
  Future<void> updateLastSyncTimestamp(String entityType, DateTime timestamp, {required int userId}) async {
    await into(syncMetadata).insert(
      SyncMetadataCompanion(
        entityType: Value(entityType),
        userId: Value(userId),
        lastSyncTimestamp: Value(timestamp.toUtc()), // Храним в UTC
        updatedAt: Value(DateTime.now().toUtc()), // Обновляем время изменения
        // syncVersion будет установлен в дефолтное значение (1) при первой вставке
      ),
      onConflict: DoUpdate(
        (old) => SyncMetadataCompanion(
          lastSyncTimestamp: Value(timestamp.toUtc()), // Обновляем только timestamp
          updatedAt: Value(DateTime.now().toUtc()), // Обновляем время изменения
          // syncVersion остается прежним, поэтому не указываем его здесь для обновления
        ),
        where: (old) => old.entityType.equals(entityType) & old.userId.equals(userId),
      ),
    );
  }

  /// Получает версию синхронизации для указанной сущности и пользователя.
  /// Возвращает дефолтное значение (1), если метаданды для этой сущности еще не существуют.
  Future<int> getSyncVersion(String entityType, {required int userId}) async {
    final entry = await (select(syncMetadata)
          ..where((t) => t.entityType.equals(entityType) & t.userId.equals(userId)))
        .getSingleOrNull();
    // Если запись не найдена, возвращаем дефолтную версию 1.
    return entry?.syncVersion ?? 1;
  }

  /// Обновляет версию синхронизации для указанной сущности и пользователя.
  /// Если запись для сущности не существует, она будет создана.
  Future<void> updateSyncVersion(String entityType, int version, {required int userId}) async {
    await into(syncMetadata).insert(
      SyncMetadataCompanion(
        entityType: Value(entityType),
        userId: Value(userId),
        syncVersion: Value(version),
        updatedAt: Value(DateTime.now().toUtc()), // Обновляем время изменения
      ),
      onConflict: DoUpdate(
        (old) => SyncMetadataCompanion(
          syncVersion: Value(version), 
          updatedAt: Value(DateTime.now().toUtc())
        ), 
        where: (old) => old.entityType.equals(entityType) & old.userId.equals(userId)
      ),
    );
  }

  /// Удаляет метаданные для указанной сущности и пользователя.
  Future<void> clearSyncMetadata(String entityType, {required int userId}) async {
    await (delete(syncMetadata)
          ..where((t) => t.entityType.equals(entityType) & t.userId.equals(userId)))
        .go();
  }
}