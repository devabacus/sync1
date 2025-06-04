// lib/features/home/presentation/providers/sync_controller_provider.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers/category/category_data_providers.dart';

part 'sync_controller_provider.g.dart';

@riverpod
class SyncController extends _$SyncController {
  StreamSubscription? _subscription;

  @override
  void build() {
    // Слушаем изменения статуса сети
    _subscription = Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
    
    // При уничтожении провайдера отписываемся от прослушивания
    ref.onDispose(() {
      _subscription?.cancel();
    });
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    // Нас интересует только момент, когда соединение появляется, а не когда пропадает.
    // Проверяем, что результат не 'none'.
    final isOnline = results.any((result) => result != ConnectivityResult.none);

    if (isOnline) {
      print('✅ Обнаружено подключение к сети. Запускаем синхронизацию...');
      try {
        // Вызываем наш метод синхронизации из репозитория
        await ref.read(categoryRepositoryProvider).syncWithServer();
        print('👍 Синхронизация успешно запущена.');
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
        await ref.read(categoryRepositoryProvider).syncWithServer();
        print('👍 Ручная синхронизация успешно запущена.');
      } catch (e) {
        print('❌ Ошибка во время ручной синхронизации: $e');
      }
  }
}