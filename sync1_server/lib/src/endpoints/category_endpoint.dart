import 'package:serverpod/serverpod.dart';
import 'package:sync1_server/src/generated/protocol.dart';

// Уникальное имя канала для сообщений о категориях
const _categoryChannel = 'sync1_category_updates';

class CategoryEndpoint extends Endpoint {
  

  /// Получает категории, измененные после указанного времени
Future<List<Category>> getCategoriesSince(Session session, DateTime? since) async {
  if (since == null) {
    // Если since не указан, возвращаем все категории
    return await getCategories(session);
  }
  
  return await Category.db.find(
    session,
    where: (c) => c.lastModified>=since,
    orderBy: (c) => c.lastModified,
  );
}

  /// Отправляет уведомление всем подписчикам канала.
  Future<void> _notifyChange(Session session, String changeType) async {
    final message = Greeting(
      message: changeType,
      author: 'Server.CategoryEndpoint',
      timestamp: DateTime.now(),
    );
    
    await session.messages.postMessage(
      _categoryChannel, 
      message,
    );
    session.log('🔔 Уведомление отправлено в канал "$_categoryChannel": $changeType');
  }

   Future<Category> createCategory(Session session, Category category) async {
    // Создаем копию объекта, но с серверным временем
    final serverCategory = category.copyWith(
      lastModified: DateTime.now().toUtc(),
    );
    await Category.db.insertRow(session, serverCategory);
    await _notifyChange(session, 'CREATE');
    return serverCategory;
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
      // Точно так же перезаписываем время при обновлении
      final serverCategory = category.copyWith(
        lastModified: DateTime.now().toUtc(),
      );
      await Category.db.updateRow(session, serverCategory);
      await _notifyChange(session, 'UPDATE');
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
        await _notifyChange(session, 'DELETE');
      }
      
      return result.isNotEmpty;
    } catch (e) {
      session.log('❌ Ошибка удаления категории: $e');
      return false;
    }
  }

  /// Production-ready real-time streaming (синтаксис Serverpod 2.x)
  Stream<List<Category>> watchCategories(Session session) async* {
    session.log('🟢 Клиент подписался на канал "$_categoryChannel"');
    
    try {
      // 1. Сразу отправляем текущий список.
      yield await getCategories(session);
      
      await for (var _ in session.messages.createStream(_categoryChannel)) {
        session.log('🔄 Получено сообщение-триггер из Redis, отправляем обновленный список.');
        
        // При получении любого сообщения, просто заново запрашиваем и отдаем полный список.
        yield await getCategories(session);
      }
    } finally {
      session.log('🔴 Клиент отписался от канала "$_categoryChannel"');
    }
  }
}