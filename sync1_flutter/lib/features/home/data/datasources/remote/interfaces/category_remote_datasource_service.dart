import 'package:sync1_client/sync1_client.dart';

/// Интерфейс для работы с категориями на удаленном сервере
/// Использует модели из sync1_client (Serverpod generated)
abstract class ICategoryRemoteDataSource {
  /// Получить все категории с сервера
  Future<List<Category>> getCategories();

  /// Получить категорию по ID с сервера
  Future<Category?> getCategoryById(UuidValue id);

  /// Создать новую категорию на сервере
  /// Возвращает созданную категорию с подтвержденными данными сервера
  Future<Category> createCategory(Category category);

  /// Обновить существующую категорию на сервере
  /// Возвращает true при успешном обновлении
  Future<bool> updateCategory(Category category);

  /// Удалить категорию на сервере по ID
  /// Возвращает true при успешном удалении
  Future<bool> deleteCategory(UuidValue id);

  /// Real-time поток всех категорий с сервера
  /// Основной метод для получения обновлений в реальном времени
  Stream<List<Category>> watchCategories();

  /// Проверить подключение к серверу
  /// Полезно для определения online/offline статуса
  Future<bool> checkConnection();

  /// Синхронизировать локальные категории с сервером
  /// Отправляет список локальных категорий и получает актуальный список с сервера
  /// Возвращает объединенный список для синхронизации
  Future<List<Category>> syncCategories(List<Category> localCategories);

  /// Закрыть все активные stream подключения
  Future<void> closeStreams();
    Future<List<Category>> getCategoriesSince(DateTime? since); 

}