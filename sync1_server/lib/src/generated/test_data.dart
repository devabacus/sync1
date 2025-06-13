/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

abstract class TestData
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  TestData._({
    this.id,
    required this.title,
  });

  factory TestData({
    _i1.UuidValue? id,
    required String title,
  }) = _TestDataImpl;

  factory TestData.fromJson(Map<String, dynamic> jsonSerialization) {
    return TestData(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      title: jsonSerialization['title'] as String,
    );
  }

  static final t = TestDataTable();

  static const db = TestDataRepository._();

  @override
  _i1.UuidValue? id;

  String title;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [TestData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TestData copyWith({
    _i1.UuidValue? id,
    String? title,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id?.toJson(),
      'title': title,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id?.toJson(),
      'title': title,
    };
  }

  static TestDataInclude include() {
    return TestDataInclude._();
  }

  static TestDataIncludeList includeList({
    _i1.WhereExpressionBuilder<TestDataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TestDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TestDataTable>? orderByList,
    TestDataInclude? include,
  }) {
    return TestDataIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TestData.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TestData.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TestDataImpl extends TestData {
  _TestDataImpl({
    _i1.UuidValue? id,
    required String title,
  }) : super._(
          id: id,
          title: title,
        );

  /// Returns a shallow copy of this [TestData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TestData copyWith({
    Object? id = _Undefined,
    String? title,
  }) {
    return TestData(
      id: id is _i1.UuidValue? ? id : this.id,
      title: title ?? this.title,
    );
  }
}

class TestDataTable extends _i1.Table<_i1.UuidValue?> {
  TestDataTable({super.tableRelation}) : super(tableName: 'test_data') {
    title = _i1.ColumnString(
      'title',
      this,
    );
  }

  late final _i1.ColumnString title;

  @override
  List<_i1.Column> get columns => [
        id,
        title,
      ];
}

class TestDataInclude extends _i1.IncludeObject {
  TestDataInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => TestData.t;
}

class TestDataIncludeList extends _i1.IncludeList {
  TestDataIncludeList._({
    _i1.WhereExpressionBuilder<TestDataTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TestData.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => TestData.t;
}

class TestDataRepository {
  const TestDataRepository._();

  /// Returns a list of [TestData]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<TestData>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TestDataTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TestDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TestDataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<TestData>(
      where: where?.call(TestData.t),
      orderBy: orderBy?.call(TestData.t),
      orderByList: orderByList?.call(TestData.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [TestData] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<TestData?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TestDataTable>? where,
    int? offset,
    _i1.OrderByBuilder<TestDataTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TestDataTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<TestData>(
      where: where?.call(TestData.t),
      orderBy: orderBy?.call(TestData.t),
      orderByList: orderByList?.call(TestData.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [TestData] by its [id] or null if no such row exists.
  Future<TestData?> findById(
    _i1.Session session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<TestData>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [TestData]s in the list and returns the inserted rows.
  ///
  /// The returned [TestData]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<TestData>> insert(
    _i1.Session session,
    List<TestData> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<TestData>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [TestData] and returns the inserted row.
  ///
  /// The returned [TestData] will have its `id` field set.
  Future<TestData> insertRow(
    _i1.Session session,
    TestData row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TestData>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TestData]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TestData>> update(
    _i1.Session session,
    List<TestData> rows, {
    _i1.ColumnSelections<TestDataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TestData>(
      rows,
      columns: columns?.call(TestData.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TestData]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TestData> updateRow(
    _i1.Session session,
    TestData row, {
    _i1.ColumnSelections<TestDataTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TestData>(
      row,
      columns: columns?.call(TestData.t),
      transaction: transaction,
    );
  }

  /// Deletes all [TestData]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TestData>> delete(
    _i1.Session session,
    List<TestData> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TestData>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TestData].
  Future<TestData> deleteRow(
    _i1.Session session,
    TestData row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TestData>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TestData>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TestDataTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TestData>(
      where: where(TestData.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TestDataTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TestData>(
      where: where?.call(TestData.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
