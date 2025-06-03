import '../../../features/home/data/datasources/local/tables/category_table.dart';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../features/home/data/datasources/local/tables/sync_metadata_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [CategoryTable, SyncMetadata])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3; // Увеличиваем версию схемы

@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
            
        if (from < 2) { // Миграция с версии 1 на 2
          // Добавляем колонки в CategoryTable
          await m.addColumn(categoryTable, categoryTable.lastModified);
          await m.addColumn(categoryTable, categoryTable.deleted);
          await m.addColumn(categoryTable, categoryTable.syncStatus);
        }
        if (from < 3) { // Миграция с версии 2 (или 1) на 3
          // Создаем новую таблицу SyncMetadata
          await m.createTable(syncMetadata);
        }
      },
    );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'sync1_flutter',
    );
  }
}
