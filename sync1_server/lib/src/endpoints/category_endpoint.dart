// sync1_server/lib/src/endpoints/category_endpoint.dart
// Замените содержимое файла на это:

import 'dart:async';
import 'package:serverpod/serverpod.dart';
import 'package:sync1_server/src/generated/protocol.dart';

class CategoryEndpoint extends Endpoint {
  // Глобальный broadcast stream для уведомлений
  static final StreamController<void> _changeNotifier = 
      StreamController<void>.broadcast();

  Future<Category> createCategory(Session session, Category category) async {
    await Category.db.insertRow(session, category);
    
    // Уведомляем о изменении
    _notifyChange(session, 'CREATE');
    
    return category;
  }

  Future<Category?> getCategoryById(Session session, UuidValue id) async {
    return await Category.db.findById(session, id);
  }

  Future<List<Category>> getCategories(Session session) async {
    return await Category.db.find(
      session,
      orderBy: (c) => c.title,
    );
  }

  Future<bool> updateCategory(Session session, Category category) async {
    try {
      await Category.db.updateRow(session, category);
      
      // Уведомляем о изменении
      _notifyChange(session, 'UPDATE');
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(Session session, UuidValue id) async {
    try {
      var result = await Category.db.deleteWhere(
        session,
        where: (c) => c.id.equals(id),
      );
      
      if (result.isNotEmpty) {
        // Уведомляем о изменении
        _notifyChange(session, 'DELETE');
      }
      
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Эффективный real-time streaming без polling
  Stream<List<Category>> watchCategories(Session session) async* {
    session.log('🟢 Клиент подключился к real-time категориям');
    
    try {
      // 1. Отправляем текущий список сразу
      var categories = await _getCurrentCategories(session);
      yield categories;
      session.log('📤 Отправлен начальный список: ${categories.length} категорий');

      // 2. Слушаем изменения через broadcast stream
      await for (var _ in _changeNotifier.stream) {
        try {
          // Получаем обновленные данные только при изменении
          var updatedCategories = await _getCurrentCategories(session);
          yield updatedCategories;
          session.log('🔄 Отправлено обновление: ${updatedCategories.length} категорий');
        } catch (e) {
          session.log('❌ Ошибка получения обновленных категорий: $e');
          // Не прерываем stream при ошибке
        }
      }
      
    } catch (e) {
      session.log('❌ Критическая ошибка в watchCategories: $e');
      rethrow;
    } finally {
      session.log('🔴 Клиент отключился от real-time категорий');
    }
  }

  /// Получает текущий список категорий
  Future<List<Category>> _getCurrentCategories(Session session) async {
    return await Category.db.find(
      session,
      orderBy: (c) => c.title,
    );
  }

  /// Уведомляет всех слушателей об изменении
  static void _notifyChange(Session session, String operation) {
    try {
      if (!_changeNotifier.isClosed) {
        _changeNotifier.add(null);
        session.log('🔔 Уведомление отправлено: $operation');
      }
    } catch (e) {
      session.log('❌ Ошибка отправки уведомления: $e');
    }
  }

  /// Очистка ресурсов при остановке сервера
  static void dispose() {
    if (!_changeNotifier.isClosed) {
      _changeNotifier.close();
    }
  }
}