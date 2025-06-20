import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sync1_client/sync1_client.dart';
import 'package:serverpod_auth_shared_flutter/serverpod_auth_shared_flutter.dart';
import '../config/config.dart';

part 'serverpod_client_provider.g.dart';

/// Конфигурация для Serverpod клиента
class ServerpodConfig {
  final String serverUrl;
  final bool enableLogging;

  const ServerpodConfig({
    required this.serverUrl,
    this.enableLogging = true,
  });
}

/// Провайдер конфигурации Serverpod
@riverpod
ServerpodConfig serverpodConfig(Ref ref) {
  return ServerpodConfig(
    serverUrl: AppConfig.baseUrl,
    enableLogging: true,
  );
}

/// Основной провайдер Serverpod клиента
@riverpod
Client serverpodClient(Ref ref) {
  ref.keepAlive();
  final config = ref.watch(serverpodConfigProvider);
  
  // Создаем клиент с authenticationKeyManager
  final client = Client(
    config.serverUrl,
    authenticationKeyManager: FlutterAuthenticationKeyManager(),
  );

  if (config.enableLogging) {
    print('Serverpod client создан для ${config.serverUrl}');
  }

  // Очистка ресурсов при dispose
  ref.onDispose(() {
    if (config.enableLogging) {
      print('Serverpod client dispose');
    }
  });

  return client;
}

/// Провайдер для проверки подключения к серверу
@riverpod
Future<bool> serverpodConnectionCheck(Ref ref) async {
  final client = ref.watch(serverpodClientProvider);
  
  try {
    await client.category.getCategories();
    return true;
  } catch (e) {
    print('Ошибка подключения к серверу: $e');
    return false;
  }
}

/// Простое перечисление состояний подключения
enum ConnectionStatus {
  unknown,
  connected,
  disconnected,
}

/// Расширение для удобной работы со статусами
extension ConnectionStatusExtension on ConnectionStatus {
  bool get isConnected => this == ConnectionStatus.connected;
  bool get isDisconnected => this == ConnectionStatus.disconnected;
  bool get isUnknown => this == ConnectionStatus.unknown;

  String get displayName {
    switch (this) {
      case ConnectionStatus.connected:
        return 'Подключен';
      case ConnectionStatus.disconnected:
        return 'Отключен';
      case ConnectionStatus.unknown:
        return 'Неизвестно';
    }
  }

  /// Цвет для отображения статуса в UI
  String get colorName {
    switch (this) {
      case ConnectionStatus.connected:
        return 'green';
      case ConnectionStatus.disconnected:
        return 'red';
      case ConnectionStatus.unknown:
        return 'grey';
    }
  }
}