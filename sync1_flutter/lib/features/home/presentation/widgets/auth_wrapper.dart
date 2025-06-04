import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_email_flutter/serverpod_auth_email_flutter.dart';
import '../../../../core/providers/session_manager_provider.dart';
import '../../../../core/providers/serverpod_client_provider.dart';
import '../../../home/presentation/pages/home_page.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsync = ref.watch(userInfoStreamProvider);
    
    return userInfoAsync.when(
      data: (userInfo) {
        if (userInfo != null) {
          // Пользователь авторизован - показываем основное приложение
          return const HomePage();
        } else {
          // Пользователь не авторизован - показываем экран входа
          return Scaffold(
            appBar: AppBar(
              title: const Text('Вход в систему'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Добро пожаловать!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Войдите в систему для продолжения',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    SignInWithEmailButton(
                      caller: ref.read(serverpodClientProvider).modules.auth,
                      onSignedIn: () {
                        // Callback выполнится автоматически при успешном входе
                        debugPrint('✅ Пользователь успешно вошел в систему');
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка аутентификации: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userInfoStreamProvider),
                child: const Text('Попробовать снова'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}