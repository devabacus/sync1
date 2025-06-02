import 'dart:async';
import 'package:sync1_client/sync1_client.dart' as serverpod;
import '../datasources/local/interfaces/category_local_datasource_service.dart';
import '../datasources/remote/interfaces/category_remote_datasource_service.dart';
import '../models/extensions/category_model_extension.dart';
import '../../domain/entities/extensions/category_entity_extension.dart';
import '../../domain/entities/category/category.dart';
import '../../domain/repositories/category_repository.dart';

/// Offline-first Repository для категорий
/// Работает с локальным (Drift) и удаленным (Serverpod) источниками данных
class CategoryRepositoryImpl implements ICategoryRepository {
  final ICategoryLocalDataSource _localDataSource;
  final ICategoryRemoteDataSource _remoteDataSource;

  CategoryRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      // Offline-first: всегда возвращаем локальные данные
      final localCategories = await _localDataSource.getCategories();
      return localCategories.toEntities();
    } catch (e) {
      print('Ошибка получения локальных категорий: $e');
      rethrow;
    }
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    // Основной поток - всегда из локальной БД для максимальной отзывчивости
    return _localDataSource.watchCategories().map(
      (models) => models.toEntities(),
    );
  }

  @override
  Future<CategoryEntity> getCategoryById(String id) async {
    try {
      final model = await _localDataSource.getCategoryById(id);
      return model.toEntity();
    } catch (e) {
      print('Ошибка получения категории по ID $id: $e');
      rethrow;
    }
  }

  @override
Future<String> createCategory(CategoryEntity category) async {
  print('🔵 Repository: Создаем категорию локально: ${category.title}');
  
  // 1. Сохраняем локально
  final localId = await _localDataSource.createCategory(category.toModel());
  print('✅ Repository: Локально сохранено с ID: $localId');
  
  // 2. Синхронизируем с сервером
  print('🌐 Repository: Отправляем на сервер...');
  _syncCreateToServer(category).then((_) {
    print('✅ Repository: Синхронизация завершена успешно');
  }).catchError((error) {
    print('❌ Repository: Ошибка синхронизации: $error');
  });
  
  return localId;
}

  @override
  Future<bool> updateCategory(CategoryEntity category) async {
    // 1. Сначала обновляем локально
    final localResult = await _localDataSource.updateCategory(category.toModel());
    
    // 2. Асинхронно отправляем на сервер
    _syncUpdateToServer(category).catchError((error) {
      print('Ошибка синхронизации обновления на сервер: $error');
    });
    
    return localResult;
  }

  @override
  Future<bool> deleteCategory(String id) async {
    // 1. Сначала удаляем локально
    final localResult = await _localDataSource.deleteCategory(id);
    
    // 2. Асинхронно удаляем на сервере
    _syncDeleteToServer(id).catchError((error) {
      print('Ошибка синхронизации удаления на сервер: $error');
    });
    
    return localResult;
  }

  /// Синхронизирует создание категории с сервером
  Future<void> _syncCreateToServer(CategoryEntity category) async {
    try {
      // Конвертируем в Serverpod модель
      final serverpodCategory = serverpod.Category(
        id: serverpod.UuidValue.fromString(category.id),
        title: category.title,
      );
      
      await _remoteDataSource.createCategory(serverpodCategory);
      print('Категория успешно создана на сервере: ${category.title}');
    } catch (e) {
      print('Не удалось создать категорию на сервере: $e');
      rethrow;
    }
  }

  /// Синхронизирует обновление категории с сервером
  Future<void> _syncUpdateToServer(CategoryEntity category) async {
    try {
      final serverpodCategory = serverpod.Category(
        id: serverpod.UuidValue.fromString(category.id),
        title: category.title,
      );
      
      await _remoteDataSource.updateCategory(serverpodCategory);
      print('Категория успешно обновлена на сервере: ${category.title}');
    } catch (e) {
      print('Не удалось обновить категорию на сервере: $e');
      rethrow;
    }
  }

  /// Синхронизирует удаление категории с сервером
  Future<void> _syncDeleteToServer(String id) async {
    try {
      final uuidValue = serverpod.UuidValue.fromString(id);
      await _remoteDataSource.deleteCategory(uuidValue);
      print('Категория успешно удалена на сервере: $id');
    } catch (e) {
      print('Не удалось удалить категорию на сервере: $e');
      rethrow;
    }
  }

   Future<void> syncWithServer() async {
    try {
      print('Начинаем синхронизацию с сервером...');
      
      // 1. Получаем все категории с сервера
      final serverCategories = await _remoteDataSource.getCategories();
      
      // 2. Получаем все локальные категории
      final localCategories = await _localDataSource.getCategories();

      // 3. Преобразуем списки в карты для удобного доступа по ID
      final serverMap = {for (var cat in serverCategories) cat.id.toString(): cat};
      final localMap = {for (var cat in localCategories) cat.id: cat};

      // 4. Обновляем и добавляем категории с сервера в локальную базу
      for (final serverCategory in serverCategories) {
        final serverCatId = serverCategory.id.toString();
        final localCategory = localMap[serverCatId];

        final categoryToUpsert = CategoryEntity(
          id: serverCatId,
          title: serverCategory.title
        ).toModel();

        if (localCategory == null) {
          // Категория есть на сервере, но нет локально -> добавляем
          print('Sync: Добавляем локально категорию с сервера: ${categoryToUpsert.title}');
          await _localDataSource.createCategory(categoryToUpsert);
        } else if (localCategory.title != serverCategory.title) {
          // Категория есть и там, и там, но отличается -> обновляем локальную
           print('Sync: Обновляем локально категорию с сервера: ${categoryToUpsert.title}');
          await _localDataSource.updateCategory(categoryToUpsert);
        }
      }

      // 5. Загружаем на сервер локально созданные категории
      for (final localCategory in localCategories) {
        if (!serverMap.containsKey(localCategory.id)) {
           print('Sync: Загружаем на сервер новую локальную категорию: ${localCategory.title}');
          await _syncCreateToServer(localCategory.toEntity());
        }
      }

      print('Синхронизация завершена.');
      
    } catch (e) {
      print('Ошибка синхронизации с сервером: $e');
      rethrow;
    }
  }

  /// Проверка подключения к серверу
  Future<bool> isServerAvailable() async {
    try {
      return await _remoteDataSource.checkConnection();
    } catch (e) {
      return false;
    }
  }

  /// Подписка на изменения с сервера для синхронизации
  /// В production это может запускаться периодически или при восстановлении соединения
  Stream<List<CategoryEntity>> watchServerChanges() async* {
    try {
      await for (final serverCategories in _remoteDataSource.watchCategories()) {
        // Конвертируем Serverpod модели в Entity
        final entities = serverCategories.map((serverpodCategory) => 
          CategoryEntity(
            id: serverpodCategory.id!.toString(),
            title: serverpodCategory.title,
          )
        ).toList();
        
        yield entities;
        
        // TODO: Здесь можно добавить логику автоматической синхронизации
        // с локальной БД при получении изменений с сервера
      }
    } catch (e) {
      print('Ошибка в потоке изменений сервера: $e');
    }
  }
}