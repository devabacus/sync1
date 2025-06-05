// lib/features/home/presentation/providers/sync_controller_provider.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';

import '../../../../core/providers/session_manager_provider.dart';
import '../../data/providers/category/category_data_providers.dart';

part 'sync_controller_provider.g.dart';

@riverpod
class SyncController extends _$SyncController {
  StreamSubscription? _connectivitySubscription;
  ProviderSubscription? _userSubscription;
  int? _currentUserId;

  @override
  void build() {
    // Слушаем изменения статуса сети
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
    
    // Слушаем смену пользователя
    _userSubscription = ref.listen(userInfoStreamProvider, (previous, next) {
      _handleUserChange(previous?.valueOrNull, next.valueOrNull);
    });
    
    // При уничтожении провайдера отписываемся от прослушивания
    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _userSubscription?.close();
    });

    // Инициализируем текущего пользователя
    final currentUser = ref.read(currentUserProvider);
    _currentUserId = currentUser?.id;
  }

  void _handleUserChange(UserInfo? previousUser, UserInfo? currentUser) async {
    final previousUserId = previousUser?.id;
    final currentUserId = currentUser?.id;

    print('👤 Смена пользователя: $previousUserId -> $currentUserId');

    // Сохраняем новый ID пользователя
    _currentUserId = currentUserId;

    if (currentUserId != null && previousUserId != currentUserId) {
      // Пользователь сменился (вход нового пользователя или переключение)
      print('🔄 Обнаружена смена пользователя. Запускаем полную синхронизацию...');
      
      try {
        // Получаем репозиторий для нового пользователя
        final repository = ref.read(currentUserCategoryRepositoryProvider);
        
        if (repository != null) {
          // Сбрасываем метаданные синхронизации, чтобы получить все данные с сервера
          await _resetSyncMetadata();
          
          // Запускаем полную синхронизацию
          await repository.syncWithServer();
          print('✅ Синхронизация после смены пользователя завершена успешно.');
        } else {
          print('⚠️ Не удалось получить репозиторий для нового пользователя.');
        }
      } catch (e) {
        print('❌ Ошибка при синхронизации после смены пользователя: $e');
      }
    } else if (currentUserId == null && previousUserId != null) {
      // Пользователь вышел из системы
      print('👋 Пользователь вышел из системы. Очистка состояния...');
    }
  }

  Future<void> _resetSyncMetadata() async {
    try {
      final syncMetadataDao = ref.read(syncMetadataDaoProvider);
      
      // Сбрасываем метаданные синхронизации для категорий
      // Это заставит систему получить все данные с сервера заново
      await syncMetadataDao.clearSyncMetadata('categories');
      
      print('🗑️ Метаданные синхронизации сброшены. Следующая синхронизация будет полной.');
    } catch (e) {
      print('⚠️ Ошибка при сбросе метаданных синхронизации: $e');
    }
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    // Нас интересует только момент, когда соединение появляется, а не когда пропадает.
    // Проверяем, что результат не 'none'.
    final isOnline = results.any((result) => result != ConnectivityResult.none);

    if (isOnline) {
      print('✅ Обнаружено подключение к сети. Запускаем синхронизацию...');
      
      // Проверяем, что пользователь авторизован
      if (_currentUserId == null) {
        print('ℹ️ Пользователь не авторизован. Синхронизация пропущена.');
        return;
      }
      
      try {
        // Получаем репозиторий текущего пользователя
        final repository = ref.read(currentUserCategoryRepositoryProvider);
        
        if (repository != null) {
          // Вызываем наш метод синхронизации из репозитория
          await repository.syncWithServer();
          print('👍 Синхронизация при восстановлении сети успешно запущена.');
        } else {
          print('ℹ️ Пользователь не авторизован. Синхронизация пропущена.');
        }
      } catch (e) {
        print('❌ Ошибка во время автоматической синхронизации: $e');
      }
    } else {
      print('🔌 Обнаружено отключение от сети.');
    }
  }

  // Метод для ручного вызова синхронизации из UI, если потребуется
  Future<void> triggerSync() async {
    print('🔄 Запуск ручной синхронизации...');
    
    try {
      // Получаем репозиторий текущего пользователя
      final repository = ref.read(currentUserCategoryRepositoryProvider);
      
      if (repository != null) {
        await repository.syncWithServer();
        print('👍 Ручная синхронизация успешно завершена.');
      } else {
        print('ℹ️ Пользователь не авторизован. Синхронизация невозможна.');
        throw Exception('Пользователь не авторизован');
      }
    } catch (e) {
      print('❌ Ошибка во время ручной синхронизации: $e');
      rethrow;
    }
  }

  // Метод для принудительной полной синхронизации (сброс метаданных + синхронизация)
  Future<void> triggerFullSync() async {
    print('🔄 Запуск принудительной полной синхронизации...');
    
    try {
      // Получаем репозиторий текущего пользователя
      final repository = ref.read(currentUserCategoryRepositoryProvider);
      
      if (repository != null) {
        // Сбрасываем метаданные синхронизации
        await _resetSyncMetadata();
        
        // Запускаем синхронизацию
        await repository.syncWithServer();
        print('👍 Принудительная полная синхронизация успешно завершена.');
      } else {
        print('ℹ️ Пользователь не авторизован. Синхронизация невозможна.');
        throw Exception('Пользователь не авторизован');
      }
    } catch (e) {
      print('❌ Ошибка во время принудительной полной синхронизации: $e');
      rethrow;
    }
  }
}