import 'package:drift/drift.dart';

/// Таблица для хранения метаданных синхронизации для различных сущностей.
@DataClassName('SyncMetadataEntry')
class SyncMetadata extends Table {
  /// Тип сущности, для которой хранятся метаданные (например, 'categories', 'users').
  /// Является первичным ключом.
  TextColumn get entityType => text()();
  IntColumn get userId => integer()();

  /// Время последней успешной синхронизации для данной сущности.
  /// Хранится в UTC. Может быть null, если синхронизация еще не проводилась.
  DateTimeColumn get lastSyncTimestamp => dateTime().nullable()();
  
  /// Версия протокола синхронизации или структуры данных,
  /// с которой была произведена последняя синхронизация.
  /// Используется для будущих миграций и управления изменениями.
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  /// Время последнего обновления этой записи метаданных.
  /// Хранится в UTC.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {entityType};
}