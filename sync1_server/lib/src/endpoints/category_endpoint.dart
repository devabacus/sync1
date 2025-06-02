// sync1_server/lib/src/endpoints/category_endpoint.dart
// Простое и надёжное production решение

import 'dart:async';
import 'package:serverpod/serverpod.dart';
import 'package:sync1_server/src/generated/protocol.dart';

class CategoryEndpoint extends Endpoint {
  // Broadcast stream для мгновенных уведомлений
  static final StreamController<CategoryChangeEvent> _changeNotifier = 
      StreamController<CategoryChangeEvent>.broadcast();

  // Счетчик активных подключений для мониторинга
  static int _activeConnections = 0;

  Future<Category> createCategory(Session session, Category category) async {
    await Category.db.insertRow(session, category);
    
    // Уведомляем о создании
    _notifyChange(session, CategoryChangeEvent(
      action: 'CREATE',
      categoryId: category.id.toString(),
      timestamp: DateTime.now(),
    ));
    
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
      
      // Уведомляем об обновлении
      _notifyChange(session, CategoryChangeEvent(
        action: 'UPDATE',
        categoryId: category.id.toString(),
        timestamp: DateTime.now(),
      ));
      
      return true;
    } catch (e) {
      session.log('❌ Ошибка обновления категории: $e');
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
        // Уведомляем об удалении
        _notifyChange(session, CategoryChangeEvent(
          action: 'DELETE',
          categoryId: id.toString(),
          timestamp: DateTime.now(),
        ));
      }
      
      return result.isNotEmpty;
    } catch (e) {
      session.log('❌ Ошибка удаления категории: $e');
      return false;
    }
  }

  /// Production-ready real-time streaming
  Stream<List<Category>> watchCategories(Session session) async* {
    _activeConnections++;
    session.log('🟢 Клиент подключился к real-time категориям (${_activeConnections} активных)');
    
    try {
      // 1. Отправляем текущий список сразу
      var categories = await _getCurrentCategories(session);
      yield categories;
      session.log('📤 Отправлен начальный список: ${categories.length} категорий');

      // 2. Слушаем изменения через broadcast stream
      await for (var changeEvent in _changeNotifier.stream) {
        try {
          // Получаем обновленные данные только при изменении
          var updatedCategories = await _getCurrentCategories(session);
          yield updatedCategories;
          session.log('🔄 Отправлено обновление ${changeEvent.action}: ${updatedCategories.length} категорий');
        } catch (e) {
          session.log('❌ Ошибка получения обновленных категорий: $e');
          // Не прерываем stream при ошибке
        }
      }
      
    } catch (e) {
      session.log('❌ Критическая ошибка в watchCategories: $e');
      rethrow;
    } finally {
      _activeConnections--;
      session.log('🔴 Клиент отключился от real-time категорий (${_activeConnections} активных)');
    }
  }

  /// Получает актуальный список категорий
  Future<List<Category>> _getCurrentCategories(Session session) async {
    return await Category.db.find(
      session,
      orderBy: (c) => c.title,
    );
  }

  /// Уведомляет всех слушателей об изменении
  static void _notifyChange(Session session, CategoryChangeEvent event) {
    try {
      if (!_changeNotifier.isClosed) {
        _changeNotifier.add(event);
        session.log('🔔 Уведомление отправлено: ${event.action} для ID ${event.categoryId}');
      }
    } catch (e) {
      session.log('❌ Ошибка отправки уведомления: $e');
    }
  }

  /// Получить количество активных подключений (для мониторинга)
  static int getActiveConnectionsCount() => _activeConnections;

  /// Очистка ресурсов
  static void dispose() {
    if (!_changeNotifier.isClosed) {
      _changeNotifier.close();
    }
    _activeConnections = 0;
  }
}

/// Событие изменения категории
class CategoryChangeEvent {
  final String action; // CREATE, UPDATE, DELETE
  final String categoryId;
  final DateTime timestamp;

  CategoryChangeEvent({
    required this.action,
    required this.categoryId,
    required this.timestamp,
  });

  @override
  String toString() => 'CategoryChangeEvent($action, $categoryId, $timestamp)';
}