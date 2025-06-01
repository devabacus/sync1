import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class CategoryTable extends Table {

  TextColumn get id => text().clientDefault(() => Uuid().v7())();
  TextColumn get title => text()();
  
  @override
  Set<Column> get primaryKey => {id};
}
   