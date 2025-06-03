// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CategoryTableTable extends CategoryTable
    with TableInfo<$CategoryTableTable, CategoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => Uuid().v7(),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($CategoryTableTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    lastModified,
    deleted,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryTableData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      lastModified:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}last_modified'],
          )!,
      deleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}deleted'],
          )!,
      syncStatus: $CategoryTableTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $CategoryTableTable createAlias(String alias) {
    return $CategoryTableTable(attachedDatabase, alias);
  }

  static TypeConverter<SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class CategoryTableData extends DataClass
    implements Insertable<CategoryTableData> {
  final String id;
  final String title;
  final DateTime lastModified;
  final bool deleted;
  final SyncStatus syncStatus;
  const CategoryTableData({
    required this.id,
    required this.title,
    required this.lastModified,
    required this.deleted,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['last_modified'] = Variable<DateTime>(lastModified);
    map['deleted'] = Variable<bool>(deleted);
    {
      map['sync_status'] = Variable<String>(
        $CategoryTableTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  CategoryTableCompanion toCompanion(bool nullToAbsent) {
    return CategoryTableCompanion(
      id: Value(id),
      title: Value(title),
      lastModified: Value(lastModified),
      deleted: Value(deleted),
      syncStatus: Value(syncStatus),
    );
  }

  factory CategoryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      syncStatus: serializer.fromJson<SyncStatus>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'deleted': serializer.toJson<bool>(deleted),
      'syncStatus': serializer.toJson<SyncStatus>(syncStatus),
    };
  }

  CategoryTableData copyWith({
    String? id,
    String? title,
    DateTime? lastModified,
    bool? deleted,
    SyncStatus? syncStatus,
  }) => CategoryTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    lastModified: lastModified ?? this.lastModified,
    deleted: deleted ?? this.deleted,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  CategoryTableData copyWithCompanion(CategoryTableCompanion data) {
    return CategoryTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      lastModified:
          data.lastModified.present
              ? data.lastModified.value
              : this.lastModified,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('lastModified: $lastModified, ')
          ..write('deleted: $deleted, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, lastModified, deleted, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.lastModified == this.lastModified &&
          other.deleted == this.deleted &&
          other.syncStatus == this.syncStatus);
}

class CategoryTableCompanion extends UpdateCompanion<CategoryTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> lastModified;
  final Value<bool> deleted;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const CategoryTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.deleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryTableCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required DateTime lastModified,
    this.deleted = const Value.absent(),
    required SyncStatus syncStatus,
    this.rowid = const Value.absent(),
  }) : title = Value(title),
       lastModified = Value(lastModified),
       syncStatus = Value(syncStatus);
  static Insertable<CategoryTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? lastModified,
    Expression<bool>? deleted,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (lastModified != null) 'last_modified': lastModified,
      if (deleted != null) 'deleted': deleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? lastModified,
    Value<bool>? deleted,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return CategoryTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      lastModified: lastModified ?? this.lastModified,
      deleted: deleted ?? this.deleted,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $CategoryTableTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('lastModified: $lastModified, ')
          ..write('deleted: $deleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoryTableTable categoryTable = $CategoryTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [categoryTable];
}

typedef $$CategoryTableTableCreateCompanionBuilder =
    CategoryTableCompanion Function({
      Value<String> id,
      required String title,
      required DateTime lastModified,
      Value<bool> deleted,
      required SyncStatus syncStatus,
      Value<int> rowid,
    });
typedef $$CategoryTableTableUpdateCompanionBuilder =
    CategoryTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime> lastModified,
      Value<bool> deleted,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

class $$CategoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryTableTable> {
  $$CategoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$CategoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryTableTable> {
  $$CategoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryTableTable> {
  $$CategoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );
}

class $$CategoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryTableTable,
          CategoryTableData,
          $$CategoryTableTableFilterComposer,
          $$CategoryTableTableOrderingComposer,
          $$CategoryTableTableAnnotationComposer,
          $$CategoryTableTableCreateCompanionBuilder,
          $$CategoryTableTableUpdateCompanionBuilder,
          (
            CategoryTableData,
            BaseReferences<
              _$AppDatabase,
              $CategoryTableTable,
              CategoryTableData
            >,
          ),
          CategoryTableData,
          PrefetchHooks Function()
        > {
  $$CategoryTableTableTableManager(_$AppDatabase db, $CategoryTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CategoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$CategoryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CategoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryTableCompanion(
                id: id,
                title: title,
                lastModified: lastModified,
                deleted: deleted,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String title,
                required DateTime lastModified,
                Value<bool> deleted = const Value.absent(),
                required SyncStatus syncStatus,
                Value<int> rowid = const Value.absent(),
              }) => CategoryTableCompanion.insert(
                id: id,
                title: title,
                lastModified: lastModified,
                deleted: deleted,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryTableTable,
      CategoryTableData,
      $$CategoryTableTableFilterComposer,
      $$CategoryTableTableOrderingComposer,
      $$CategoryTableTableAnnotationComposer,
      $$CategoryTableTableCreateCompanionBuilder,
      $$CategoryTableTableUpdateCompanionBuilder,
      (
        CategoryTableData,
        BaseReferences<_$AppDatabase, $CategoryTableTable, CategoryTableData>,
      ),
      CategoryTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoryTableTableTableManager get categoryTable =>
      $$CategoryTableTableTableManager(_db, _db.categoryTable);
}
