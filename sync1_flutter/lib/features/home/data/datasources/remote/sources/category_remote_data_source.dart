import 'dart:async';
import 'package:sync1_client/sync1_client.dart';
import '../interfaces/category_remote_datasource_service.dart';

/// Реализация работы с категориями через Serverpod сервер
class CategoryRemoteDataSource implements ICategoryRemoteDataSource {
  final Client _client;
  
  // Subscription для управления streaming подключением
  StreamSubscription<List<Category>>? _streamSubscription;
  StreamController<List<Category>>? _categoriesStreamController;
  
  CategoryRemoteDataSource(this._client);

  @override
  Future<List<Category>> getCategories() async {
    try {
      final categories = await _client.category.getCategories();
      return categories;
    } catch (e) {
      print('Ошибка получения категорий: $e');
      rethrow;
    }
  }

  @override
  Future<Category?> getCategoryById(UuidValue id) async {
    try {
      final category = await _client.category.getCategoryById(id);
      return category;
    } catch (e) {
      print('Ошибка получения категории по ID $id: $e');
      rethrow;
    }
  }

  @override
  Future<Category> createCategory(Category category) async {
    try {
      final createdCategory = await _client.category.createCategory(category);
      return createdCategory;
    } catch (e) {
      print('Ошибка создания категории: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateCategory(Category category) async {
    try {
      final result = await _client.category.updateCategory(category);
      return result;
    } catch (e) {
      print('Ошибка обновления категории: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deleteCategory(UuidValue id) async {
    try {
      final result = await _client.category.deleteCategory(id);
      return result;
    } catch (e) {
      print('Ошибка удаления категории $id: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Category>> watchCategories() {
    // Если stream уже создан, возвращаем его
    if (_categoriesStreamController != null && !_categoriesStreamController!.isClosed) {
      return _categoriesStreamController!.stream;
    }

    // Создаем новый broadcast stream controller
    _categoriesStreamController = StreamController<List<Category>>.broadcast();

    // Подключаемся к Serverpod streaming method
    _connectToServerStream();

    return _categoriesStreamController!.stream;
  }

  /// Подключается к серверному streaming методу
  void _connectToServerStream() {
    try {
      // Используем настоящий Serverpod streaming method
      final serverStream = _client.category.watchCategories();
      
      _streamSubscription = serverStream.listen(
        (categories) {
          // Перенаправляем данные в наш broadcast stream
          if (_categoriesStreamController != null && !_categoriesStreamController!.isClosed) {
            _categoriesStreamController!.add(categories);
          }
        },
        onError: (error) {
          print('Ошибка в server stream: $error');
          if (_categoriesStreamController != null && !_categoriesStreamController!.isClosed) {
            _categoriesStreamController!.addError(error);
          }
        },
        onDone: () {
          print('Server stream завершен');
          if (_categoriesStreamController != null && !_categoriesStreamController!.isClosed) {
            _categoriesStreamController!.close();
          }
        },
      );
      
      print('Подключено к Serverpod streaming method');
    } catch (e) {
      print('Ошибка подключения к server stream: $e');
      if (_categoriesStreamController != null && !_categoriesStreamController!.isClosed) {
        _categoriesStreamController!.addError(e);
      }
    }
  }

  @override
  Future<bool> checkConnection() async {
    try {
      await _client.category.getCategories();
      return true;
    } catch (e) {
      print('Проверка подключения неудачна: $e');
      return false;
    }
  }

  @override
  Future<List<Category>> syncCategories(List<Category> localCategories) async {
    try {
      // Простая стратегия синхронизации:
      // 1. Получаем все категории с сервера
      final serverCategories = await getCategories();
      
      // 2. В будущем здесь будет более сложная логика merge/conflict resolution
      // Пока просто возвращаем серверные данные как актуальные
      
      print('Синхронизация: локальных ${localCategories.length}, серверных ${serverCategories.length}');
      return serverCategories;
    } catch (e) {
      print('Ошибка синхронизации категорий: $e');
      // В случае ошибки возвращаем локальные данные
      return localCategories;
    }
  }

  @override
  Future<void> closeStreams() async {
    // Закрываем подписку на server stream
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    
    // Закрываем broadcast stream controller
    if (_categoriesStreamController != null && !_categoriesStreamController!.isClosed) {
      await _categoriesStreamController!.close();
      _categoriesStreamController = null;
    }
    
    print('Remote data source streams закрыты');
  }

  /// Освобождение ресурсов при dispose
  void dispose() {
    closeStreams();
  }
}