/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class Category implements _i1.SerializableModel {
  Category._({
    this.id,
    required this.title,
    this.lastModified,
    required this.userId,
  });

  factory Category({
    _i1.UuidValue? id,
    required String title,
    DateTime? lastModified,
    required int userId,
  }) = _CategoryImpl;

  factory Category.fromJson(Map<String, dynamic> jsonSerialization) {
    return Category(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      title: jsonSerialization['title'] as String,
      lastModified: jsonSerialization['lastModified'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastModified']),
      userId: jsonSerialization['userId'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  String title;

  DateTime? lastModified;

  int userId;

  /// Returns a shallow copy of this [Category]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Category copyWith({
    _i1.UuidValue? id,
    String? title,
    DateTime? lastModified,
    int? userId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id?.toJson(),
      'title': title,
      if (lastModified != null) 'lastModified': lastModified?.toJson(),
      'userId': userId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CategoryImpl extends Category {
  _CategoryImpl({
    _i1.UuidValue? id,
    required String title,
    DateTime? lastModified,
    required int userId,
  }) : super._(
          id: id,
          title: title,
          lastModified: lastModified,
          userId: userId,
        );

  /// Returns a shallow copy of this [Category]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Category copyWith({
    Object? id = _Undefined,
    String? title,
    Object? lastModified = _Undefined,
    int? userId,
  }) {
    return Category(
      id: id is _i1.UuidValue? ? id : this.id,
      title: title ?? this.title,
      lastModified:
          lastModified is DateTime? ? lastModified : this.lastModified,
      userId: userId ?? this.userId,
    );
  }
}
