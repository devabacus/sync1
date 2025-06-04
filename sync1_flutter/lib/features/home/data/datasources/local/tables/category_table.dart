import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// Перечисление для статусов синхронизации
enum SyncStatus { local, synced, conflict }

class CategoryTable extends Table {

  TextColumn get id => text().clientDefault(() => Uuid().v7())();
  TextColumn get title => text()();
  
  // Новые колонки для синхронизации
  DateTimeColumn get lastModified => dateTime()();
  
  // Статус синхронизации. Используем .map, чтобы Drift мог работать с нашим enum.
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Конвертер, чтобы Drift мог сохранять наш enum SyncStatus как текст в БД.
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