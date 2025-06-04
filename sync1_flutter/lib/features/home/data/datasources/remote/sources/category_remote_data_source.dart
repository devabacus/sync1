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
  Future<List<Category>> getCategoriesSince(DateTime? since) async {
    try {
      // Вызываем правильный метод на клиенте Serverpod
      final categories = await _client.category.getCategoriesSince(since);
      return categories;
    } catch (e) {
      print('Ошибка получения категорий c $since: $e');
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
    print('🚀 Remote: Отправляем на сервер: ${category.title}');
    print('🚀 Remote: Server URL: ${_client.host}'); // Проверьте URL

    try {
      final result = await _client.category.createCategory(category);
      print('✅ Remote: Успешно создано на сервере');
      return result;
    } catch (e) {
      print('❌ Remote: Ошибка создания на сервере: $e');
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
Stream<CategorySyncEvent> watchEvents() {
  try {
    // Просто возвращаем stream напрямую от клиента Serverpod
    return _client.category.watchEvents();
  } catch (e) {
    print('❌ Ошибка подписки на события сервера: $e');
    // Возвращаем пустой stream в случае ошибки, чтобы приложение не падало
    return Stream.value(CategorySyncEvent(type: SyncEventType.create));
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

      print(
        'Синхронизация: локальных ${localCategories.length}, серверных ${serverCategories.length}',
      );
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
    if (_categoriesStreamController != null &&
        !_categoriesStreamController!.isClosed) {
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
