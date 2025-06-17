// lib/features/home/presentation/providers/sync_controller_provider.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- 1. ИМПОРТ ДЛЯ ProviderSubscription
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart'; // <-- 2. ЯВНЫЙ ИМПОРТ ДЛЯ UserInfo
import '../../../../core/providers/session_manager_provider.dart';
import '../../data/providers/category/category_data_providers.dart';
import '../../data/repositories/category_repository_impl.dart';

part 'sync_controller_provider.g.dart';

@riverpod
class SyncController extends _$SyncController {
  StreamSubscription? _connectivitySubscription;
  ProviderSubscription? _authSubscription; // <-- 3. ИЗМЕНЕН ТИП ПЕРЕМЕННОЙ

  @override
  void build() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
    
    _listenToAuthChanges(); 

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _authSubscription?.close(); // <-- 4. ДЛЯ ProviderSubscription ИСПОЛЬЗУЕТСЯ .close()
    });
  }

  void _listenToAuthChanges() {
    _authSubscription = ref.listen<AsyncValue<UserInfo?>>(userInfoStreamProvider, (previous, next) {
      // Проверяем, изменилось ли состояние с "не залогинен" на "залогинен"
      final wasLoggedIn = previous?.valueOrNull != null;
      final isLoggedIn = next.valueOrNull != null;

      if (!wasLoggedIn && isLoggedIn) {
        print('✅ Обнаружен вход пользователя. Запускаем синхронизацию...');
        _triggerSync();
      }
    });
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    final isOnline = results.any((result) => result != ConnectivityResult.none);

    if (isOnline) {
  print('✅ Обнаружено подключение к сети.');
  
  // Сбрасываем счетчик для быстрого переподключения
  final repository = ref.read(currentUserCategoryRepositoryProvider);
  if (repository is CategoryRepositoryImpl) {
    repository.reconnectionAttempt = 0; // или через публичный метод
  }
  
  _triggerSync();
}

  }

  Future<void> _triggerSync() async {
    try {
      // Небольшая задержка, чтобы Riverpod успел перестроить все зависимые провайдеры
      await Future.delayed(const Duration(milliseconds: 500));
      
      final repository = ref.read(currentUserCategoryRepositoryProvider);
      
      if (repository != null) {
        print('SYNC_CONTROLLER: Вызов repository.syncWithServer() для пользователя...');
        await repository.syncWithServer();
        print('👍 Синхронизация успешно запущена.');
      } else {
        print('ℹ️ Пользователь не авторизован или репозиторий еще не готов. Синхронизация пропущена.');
      }

       if (repository is CategoryRepositoryImpl) {
        repository.initEventBasedSync(); // подписываемся на websocket 
      }
    } catch (e) {
      print('❌ Ошибка во время автоматической синхронизации: $e');
    }
  }

  Future<void> triggerSync() async {
     print('🔄 Запуск ручной синхронизации...');
     await _triggerSync();
  } 
}