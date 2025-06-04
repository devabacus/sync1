import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/home/presentation/providers/sync_controller_provider.dart';
import 'features/home/presentation/widgets/auth_wrapper.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Инициализируем контроллер синхронизации
    ref.watch(syncControllerProvider);
    
    return MaterialApp(
      title: 'Sync1 App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Убираем роутинг и используем AuthWrapper для управления состоянием
      home: const AuthWrapper(),
    );
  }
}