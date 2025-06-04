
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/routing/router_config.dart';
import 'features/home/presentation/providers/sync_controller_provider.dart';


class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncControllerProvider);
    final router = ref.read(appRouterProvider);
    return MaterialApp.router(routerConfig: router);
  }
}
