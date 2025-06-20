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
import '../endpoints/category_endpoint.dart' as _i2;
import '../endpoints/test_data_endpoint.dart' as _i3;
import '../greeting_endpoint.dart' as _i4;
import 'package:sync1_server/src/generated/category.dart' as _i5;
import 'package:uuid/uuid_value.dart' as _i6;
import 'package:sync1_server/src/generated/test_data.dart' as _i7;
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as _i8;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'category': _i2.CategoryEndpoint()
        ..initialize(
          server,
          'category',
          null,
        ),
      'testData': _i3.TestDataEndpoint()
        ..initialize(
          server,
          'testData',
          null,
        ),
      'greeting': _i4.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['category'] = _i1.EndpointConnector(
      name: 'category',
      endpoint: endpoints['category']!,
      methodConnectors: {
        'createCategory': _i1.MethodConnector(
          name: 'createCategory',
          params: {
            'category': _i1.ParameterDescription(
              name: 'category',
              type: _i1.getType<_i5.Category>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['category'] as _i2.CategoryEndpoint).createCategory(
            session,
            params['category'],
          ),
        ),
        'getCategories': _i1.MethodConnector(
          name: 'getCategories',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['category'] as _i2.CategoryEndpoint)
                  .getCategories(session),
        ),
        'getCategoryById': _i1.MethodConnector(
          name: 'getCategoryById',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<_i6.UuidValue>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['category'] as _i2.CategoryEndpoint).getCategoryById(
            session,
            params['id'],
          ),
        ),
        'getCategoriesSince': _i1.MethodConnector(
          name: 'getCategoriesSince',
          params: {
            'since': _i1.ParameterDescription(
              name: 'since',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['category'] as _i2.CategoryEndpoint)
                  .getCategoriesSince(
            session,
            params['since'],
          ),
        ),
        'updateCategory': _i1.MethodConnector(
          name: 'updateCategory',
          params: {
            'category': _i1.ParameterDescription(
              name: 'category',
              type: _i1.getType<_i5.Category>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['category'] as _i2.CategoryEndpoint).updateCategory(
            session,
            params['category'],
          ),
        ),
        'deleteCategory': _i1.MethodConnector(
          name: 'deleteCategory',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<_i6.UuidValue>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['category'] as _i2.CategoryEndpoint).deleteCategory(
            session,
            params['id'],
          ),
        ),
        'watchEvents': _i1.MethodStreamConnector(
          name: 'watchEvents',
          params: {},
          streamParams: {},
          returnType: _i1.MethodStreamReturnType.streamType,
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
            Map<String, Stream> streamParams,
          ) =>
              (endpoints['category'] as _i2.CategoryEndpoint)
                  .watchEvents(session),
        ),
      },
    );
    connectors['testData'] = _i1.EndpointConnector(
      name: 'testData',
      endpoint: endpoints['testData']!,
      methodConnectors: {
        'createTestData': _i1.MethodConnector(
          name: 'createTestData',
          params: {
            'testData': _i1.ParameterDescription(
              name: 'testData',
              type: _i1.getType<_i7.TestData>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['testData'] as _i3.TestDataEndpoint).createTestData(
            session,
            params['testData'],
          ),
        ),
        'listTestDatas': _i1.MethodConnector(
          name: 'listTestDatas',
          params: {},
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['testData'] as _i3.TestDataEndpoint)
                  .listTestDatas(session),
        ),
        'updateTestData': _i1.MethodConnector(
          name: 'updateTestData',
          params: {
            'testData': _i1.ParameterDescription(
              name: 'testData',
              type: _i1.getType<_i7.TestData>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['testData'] as _i3.TestDataEndpoint).updateTestData(
            session,
            params['testData'],
          ),
        ),
        'deleteTestData': _i1.MethodConnector(
          name: 'deleteTestData',
          params: {
            'testData': _i1.ParameterDescription(
              name: 'testData',
              type: _i1.getType<_i7.TestData>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['testData'] as _i3.TestDataEndpoint).deleteTestData(
            session,
            params['testData'],
          ),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            )
          },
          call: (
            _i1.Session session,
            Map<String, dynamic> params,
          ) async =>
              (endpoints['greeting'] as _i4.GreetingEndpoint).hello(
            session,
            params['name'],
          ),
        )
      },
    );
    modules['serverpod_auth'] = _i8.Endpoints()..initializeEndpoints(server);
  }
}
