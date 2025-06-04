// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_remote_data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryRemoteDataSourceHash() =>
    r'4d699a679ce46d219ca358bd1b55d4dda37d0c0f';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
