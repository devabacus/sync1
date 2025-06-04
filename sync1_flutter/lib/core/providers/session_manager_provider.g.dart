// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_manager_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionManagerHash() => r'b67e31ddb34c8cfdadb020f29be6df47947f230d';

/// Провайдер для SessionManager
///
/// Copied from [sessionManager].
@ProviderFor(sessionManager)
final sessionManagerProvider = AutoDisposeProvider<SessionManager>.internal(
  sessionManager,
  name: r'sessionManagerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sessionManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SessionManagerRef = AutoDisposeProviderRef<SessionManager>;
String _$userInfoStreamHash() => r'688f3d558a2101af1ec4876f83da2569c766b421';

/// Stream провайдер для отслеживания изменений пользователя
///
/// Copied from [userInfoStream].
@ProviderFor(userInfoStream)
final userInfoStreamProvider = AutoDisposeStreamProvider<UserInfo?>.internal(
  userInfoStream,
  name: r'userInfoStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userInfoStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserInfoStreamRef = AutoDisposeStreamProviderRef<UserInfo?>;
String _$currentUserHash() => r'a7754de5bf305b224c675a3f8016a175aba872a4';

/// Провайдер для получения текущего пользователя (может быть null)
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeProvider<UserInfo?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeProviderRef<UserInfo?>;
String _$isAuthenticatedHash() => r'ec341d95b490bda54e8278477e26f7b345844931';

/// Провайдер для проверки авторизации
///
/// Copied from [isAuthenticated].
@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = AutoDisposeProvider<bool>.internal(
  isAuthenticated,
  name: r'isAuthenticatedProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$isAuthenticatedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAuthenticatedRef = AutoDisposeProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
