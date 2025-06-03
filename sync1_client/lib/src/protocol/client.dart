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
import 'dart:async' as _i2;
import 'package:sync1_client/src/protocol/category.dart' as _i3;
import 'package:uuid/uuid_value.dart' as _i4;
import 'package:sync1_client/src/protocol/greeting.dart' as _i5;
import 'protocol.dart' as _i6;

/// {@category Endpoint}
class EndpointCategory extends _i1.EndpointRef {
  EndpointCategory(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'category';

  /// Получает категории, измененные после указанного времени
  _i2.Future<List<_i3.Category>> getCategoriesSince(DateTime? since) =>
      caller.callServerEndpoint<List<_i3.Category>>(
        'category',
        'getCategoriesSince',
        {'since': since},
      );

  _i2.Future<_i3.Category> createCategory(_i3.Category category) =>
      caller.callServerEndpoint<_i3.Category>(
        'category',
        'createCategory',
        {'category': category},
      );

  _i2.Future<_i3.Category?> getCategoryById(_i4.UuidValue id) =>
      caller.callServerEndpoint<_i3.Category?>(
        'category',
        'getCategoryById',
        {'id': id},
      );

  _i2.Future<List<_i3.Category>> getCategories() =>
      caller.callServerEndpoint<List<_i3.Category>>(
        'category',
        'getCategories',
        {},
      );

  _i2.Future<bool> updateCategory(_i3.Category category) =>
      caller.callServerEndpoint<bool>(
        'category',
        'updateCategory',
        {'category': category},
      );

  _i2.Future<bool> deleteCategory(_i4.UuidValue id) =>
      caller.callServerEndpoint<bool>(
        'category',
        'deleteCategory',
        {'id': id},
      );

  /// Production-ready real-time streaming (синтаксис Serverpod 2.x)
  _i2.Stream<List<_i3.Category>> watchCategories() =>
      caller.callStreamingServerEndpoint<_i2.Stream<List<_i3.Category>>,
          List<_i3.Category>>(
        'category',
        'watchCategories',
        {},
        {},
      );
}

/// This is an example endpoint that returns a greeting message through its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i5.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i5.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    _i1.AuthenticationKeyManager? authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )? onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
          host,
          _i6.Protocol(),
          securityContext: securityContext,
          authenticationKeyManager: authenticationKeyManager,
          streamingConnectionTimeout: streamingConnectionTimeout,
          connectionTimeout: connectionTimeout,
          onFailedCall: onFailedCall,
          onSucceededCall: onSucceededCall,
          disconnectStreamsOnLostInternetConnection:
              disconnectStreamsOnLostInternetConnection,
        ) {
    category = EndpointCategory(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointCategory category;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
        'category': category,
        'greeting': greeting,
      };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
