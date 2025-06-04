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
  int get schemaVersion => 1;

@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
   
      },
    );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'sync1_flutter',
    );
  }
}
