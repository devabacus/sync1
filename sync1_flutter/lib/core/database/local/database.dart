import '../../../features/home/data/datasources/local/tables/category_table.dart';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

@DriftDatabase(tables: [CategoryTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
            
        if (from < 2) {
          // Добавляем новые колонки
          await m.addColumn(categoryTable, categoryTable.lastModified);
          await m.addColumn(categoryTable, categoryTable.deleted);
          await m.addColumn(categoryTable, categoryTable.syncStatus);
        }        
        
      },
    );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'sync1_flutter',
    );
  }
}

