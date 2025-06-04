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
import 'greeting.dart' as _i2;
import 'category.dart' as _i3;
import 'category_sync_event.dart' as _i4;
import 'sync_event_type.dart' as _i5;
import 'package:sync1_client/src/protocol/category.dart' as _i6;
export 'greeting.dart';
export 'category.dart';
export 'category_sync_event.dart';
export 'sync_event_type.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    if (t == _i2.Greeting) {
      return _i2.Greeting.fromJson(data) as T;
    }
    if (t == _i3.Category) {
      return _i3.Category.fromJson(data) as T;
    }
    if (t == _i4.CategorySyncEvent) {
      return _i4.CategorySyncEvent.fromJson(data) as T;
    }
    if (t == _i5.SyncEventType) {
      return _i5.SyncEventType.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Greeting?>()) {
      return (data != null ? _i2.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Category?>()) {
      return (data != null ? _i3.Category.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.CategorySyncEvent?>()) {
      return (data != null ? _i4.CategorySyncEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.SyncEventType?>()) {
      return (data != null ? _i5.SyncEventType.fromJson(data) : null) as T;
    }
    if (t == List<_i6.Category>) {
      return (data as List).map((e) => deserialize<_i6.Category>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i2.Greeting) {
      return 'Greeting';
    }
    if (data is _i3.Category) {
      return 'Category';
    }
    if (data is _i4.CategorySyncEvent) {
      return 'CategorySyncEvent';
    }
    if (data is _i5.SyncEventType) {
      return 'SyncEventType';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i2.Greeting>(data['data']);
    }
    if (dataClassName == 'Category') {
      return deserialize<_i3.Category>(data['data']);
    }
    if (dataClassName == 'CategorySyncEvent') {
      return deserialize<_i4.CategorySyncEvent>(data['data']);
    }
    if (dataClassName == 'SyncEventType') {
      return deserialize<_i5.SyncEventType>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
