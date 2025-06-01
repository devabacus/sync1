import 'package:sync1/core/database/local/database.dart';
import 'package:sync1/core/database/local/interface/i_database_service.dart';
import 'package:drift/native.dart';

class TestDatabaseService implements IDatabaseService {
  final AppDatabase _database;

  TestDatabaseService() : _database = AppDatabase(NativeDatabase.memory());

  @override
  AppDatabase get database => _database;

  @override
  Future<void> close() => database.close();
}