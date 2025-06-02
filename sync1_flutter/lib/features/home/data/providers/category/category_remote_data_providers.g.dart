// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_remote_data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryRemoteDataSourceHash() =>
    r'f44ca5112b8a15308992b8b7b80f0c045e47ada8';

/// Провайдер для Remote Data Source категорий
///
/// Copied from [categoryRemoteDataSource].
@ProviderFor(categoryRemoteDataSource)
final categoryRemoteDataSourceProvider =
    AutoDisposeProvider<ICategoryRemoteDataSource>.internal(
      categoryRemoteDataSource,
      name: r'categoryRemoteDataSourceProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$categoryRemoteDataSourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoryRemoteDataSourceRef =
    AutoDisposeProviderRef<ICategoryRemoteDataSource>;
String _$categoryRemoteConnectionCheckHash() =>
    r'74d696bf088b80a2b3a960caf6d3ce6c2e6d9520';

/// Провайдер для проверки подключения к серверу
///
/// Copied from [categoryRemoteConnectionCheck].
@ProviderFor(categoryRemoteConnectionCheck)
final categoryRemoteConnectionCheckProvider =
    AutoDisposeFutureProvider<bool>.internal(
      categoryRemoteConnectionCheck,
      name: r'categoryRemoteConnectionCheckProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$categoryRemoteConnectionCheckHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoryRemoteConnectionCheckRef = AutoDisposeFutureProviderRef<bool>;
String _$categoriesFromServerHash() =>
    r'9cf3dd46091fec66c84f16a4fb89631e6bd3bc3b';

/// Провайдер для получения категорий с сервера (разовый запрос)
///
/// Copied from [categoriesFromServer].
@ProviderFor(categoriesFromServer)
final categoriesFromServerProvider =
    AutoDisposeFutureProvider<List<Category>>.internal(
      categoriesFromServer,
      name: r'categoriesFromServerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$categoriesFromServerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoriesFromServerRef = AutoDisposeFutureProviderRef<List<Category>>;
String _$categoriesStreamFromServerHash() =>
    r'81db1f4537944901e0eb361954a0bf7e75b5f60d';

/// Провайдер для real-time потока категорий с сервера
///
/// Copied from [categoriesStreamFromServer].
@ProviderFor(categoriesStreamFromServer)
final categoriesStreamFromServerProvider =
    AutoDisposeStreamProvider<List<Category>>.internal(
      categoriesStreamFromServer,
      name: r'categoriesStreamFromServerProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$categoriesStreamFromServerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoriesStreamFromServerRef =
    AutoDisposeStreamProviderRef<List<Category>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
