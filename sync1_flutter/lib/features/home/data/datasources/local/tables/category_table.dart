import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// Перечисление для статусов синхронизации
enum SyncStatus { local, synced, conflict, deleted }

class CategoryTable extends Table {

  TextColumn get id => text().clientDefault(() => Uuid().v7())();
  TextColumn get title => text()();
  IntColumn get lastModified => integer().map(const MillisecondEpochConverter())();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  IntColumn get userId => integer()();
  
  @override
  Set<Column> get primaryKey => {id};
}

class SyncStatusConverter extends TypeConverter<SyncStatus, String> {
  const SyncStatusConverter();
  @override
  SyncStatus fromSql(String fromDb) {
    return SyncStatus.values.byName(fromDb);
  }

  @override
  String toSql(SyncStatus value) {
    return value.name;
  }
}

class MillisecondEpochConverter extends TypeConverter<DateTime, int> {
  const MillisecondEpochConverter();
  
  @override
  DateTime fromSql(int fromDb) {
    return DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);
  }

  @override
  int toSql(DateTime value) {
    return value.millisecondsSinceEpoch;
  }
}