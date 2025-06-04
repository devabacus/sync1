import 'package:serverpod/serverpod.dart';
import 'package:sync1_server/src/generated/protocol.dart';

// Уникальное имя канала для сообщений о категориях
const _categoryChannel = 'sync1_category_events';

class CategoryEndpoint extends Endpoint {
  
  // Этот метод остается без изменений. Он нужен для "холодной" синхронизации.
  Future<List<Category>> getCategoriesSince(Session session, DateTime? since) async {
    if (since == null) {
      return await getCategories(session);
    }
    
    return await Category.db.find(
      session,
      where: (c) => c.lastModified >= since,
      orderBy: (c) => c.lastModified,
    );
  }

  // --- ИЗМЕНЕНИЕ: Уведомление теперь отправляет конкретное событие ---
  Future<void> _notifyChange(Session session, CategorySyncEvent event) async {
    // Отправляем объект события в канал
    await session.messages.postMessage(
      _categoryChannel, 
      event,
    );
    session.log('🔔 Событие отправлено в канал "$_categoryChannel": ${event.type.name}');
  }

   Future<Category> createCategory(Session session, Category category) async {
    final serverCategory = category.copyWith(
      lastModified: DateTime.now().toUtc(),
    );
    await Category.db.insertRow(session, serverCategory);
    
    // --- ИЗМЕНЕНИЕ: Отправляем событие о создании ---
    await _notifyChange(session, CategorySyncEvent(
      type: SyncEventType.create,
      category: serverCategory,
    ));

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
      final serverCategory = category.copyWith(
        lastModified: DateTime.now().toUtc(),
      );
      await Category.db.updateRow(session, serverCategory);
      
      // --- ИЗМЕНЕНИЕ: Отправляем событие об обновлении ---
      await _notifyChange(session, CategorySyncEvent(
        type: SyncEventType.update,
        category: serverCategory,
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
        // --- ИЗМЕНЕНИЕ: Отправляем событие об удалении ---
        await _notifyChange(session, CategorySyncEvent(
          type: SyncEventType.delete,
          id: id,
        ));
      }
      
      return result.isNotEmpty;
    } catch (e) {
      session.log('❌ Ошибка удаления категории: $e');
      return false;
    }
  }

  // --- ИЗМЕНЕНИЕ: Stream теперь отправляет события, а не весь список ---
  // Название изменено на watchEvents для ясности
  Stream<CategorySyncEvent> watchEvents(Session session) async* {
    session.log('🟢 Клиент подписался на события в канале "$_categoryChannel"');
    
    try {
      // Этот stream больше НЕ отправляет начальный список.
      // Он только транслирует события, которые происходят ПОСЛЕ подписки.
      await for (var event in session.messages.createStream<CategorySyncEvent>(_categoryChannel)) {
        session.log('🔄 Получено событие, пересылаем клиенту: ${event.type.name}');
        yield event;
      }
    } finally {
      session.log('🔴 Клиент отписался от канала "$_categoryChannel"');
    }
  }
}