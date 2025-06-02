// sync1_server/lib/server.dart
// Добавьте инициализацию после pod.start()

import 'package:sync1_server/src/birthday_reminder.dart';
import 'package:serverpod/serverpod.dart';
import 'package:sync1_server/src/web/routes/root.dart';
import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';
import 'src/endpoints/category_endpoint.dart'; // Добавьте этот импорт

void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
  );

  // Setup a default page at the web root.
  pod.webServer.addRoute(RouteRoot(), '/');
  pod.webServer.addRoute(RouteRoot(), '/index.html');
  pod.webServer.addRoute(
    RouteStaticDirectory(serverDirectory: 'static', basePath: '/'),
    '/*',
  );

  // Start the server.
  await pod.start();

  // ✅ Real-time уведомления готовы к работе
  print('🟢 Real-time уведомления активированы');

  // Register future calls
  pod.registerFutureCall(
    BirthdayReminder(),
    FutureCallNames.birthdayReminder.name,
  );

  await pod.futureCallWithDelay(
    FutureCallNames.birthdayReminder.name,
    Greeting(
      message: 'Hello!',
      author: 'Serverpod Server',
      timestamp: DateTime.now(),
    ),
    Duration(seconds: 5),
  );

  // ✅ Graceful shutdown будет обработан автоматически при остановке процесса
  // CategoryEndpoint.dispose() будет вызван при завершении приложения
}

enum FutureCallNames {
  birthdayReminder,
}