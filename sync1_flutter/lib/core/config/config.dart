
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Getter для API ключа
  static String get apiKey {
    return dotenv.env['API_KEY'] ?? '';
  }

  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? '';
  }
  
}
