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

abstract class TestData implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  String title;

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
