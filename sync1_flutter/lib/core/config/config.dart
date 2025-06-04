import 'package:flutter/foundation.dart';
import 'dart:io' show Platform; // <--- Добавьте этот импорт
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiKey {
    return dotenv.env['API_KEY'] ?? '';
  }

  static String get baseUrl {
    // В режиме отладки выбираем локальный URL
      // return dotenv.env['BASE_URL'] ?? '';


    if (kDebugMode) {
      // Проверяем, запущено ли приложение на Android
      if (Platform.isAndroid) {
        // Для эмулятора Android используем специальный адрес
        return dotenv.env['LOCAL_BASE_URL_ANDROID'] ?? 'http://10.0.2.2:8080/';
      } else {
        // Для Windows и других настольных платформ используем localhost
        return dotenv.env['LOCAL_BASE_URL_DESKTOP'] ?? 'http://localhost:8080/';
      }
    } else {
      // Для релизной сборки используем удаленный сервер
      return dotenv.env['BASE_URL'] ?? '';
    }
  }
}      