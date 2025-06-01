
// ignore_for_file: unused_field
import 'package:chopper/chopper.dart';

class ApiClient {
  final ChopperClient _client;
  
  ApiClient(this._client);

  factory ApiClient.create({
    String? baseUrl,
    bool enableLogging = true,
    String? apiKey
  }) {
    final client = ChopperClient(
      baseUrl: Uri.parse(baseUrl!),
      interceptors: [
        // DefHeadersInterceptor(),
        // HttpLoggingInterceptor(),
        // if (apiKey != null) ApiKeyInterceptor(apiKey: apiKey),
        // RetryInterceptor(maxRetries: 3),
        // ErrorInterceptor(),
      ],
      converter: JsonConverter(),
      services: [
 
      ],
    );
    
    return ApiClient(client);
  }
}

