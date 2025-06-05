import 'package:serverpod/serverpod.dart';
import 'package:sync1_server/src/generated/protocol.dart';

const _categoryChannelBase = 'sync1_category_events_for_user_';

class CategoryEndpoint extends Endpoint {
  
  Future<int> _getAuthenticatedUserId(Session session) async {
    final authInfo = await session.authenticated;
    final userId = authInfo?.userId;

    if (userId == null) {
      throw Exception('Пользователь не авторизован.');
    }
    return userId;
  }

  Future<void> _notifyChange(Session session, CategorySyncEvent event, int userId) async {
    final channel = '$_categoryChannelBase$userId';
    await session.messages.postMessage(channel, event);
    session.log('🔔 Событие ${event.type.name} отправлено в канал "$channel"');
  }

  Future<Category> createCategory(Session session, Category category) async {
    final userId = await _getAuthenticatedUserId(session);
    final serverCategory = category.copyWith(
      userId: userId,
      lastModified: DateTime.now().toUtc(),
    );
    final createdCategory = await Category.db.insertRow(session, serverCategory);
    await _notifyChange(session, CategorySyncEvent(
      type: SyncEventType.create,
      category: createdCategory,
    ), userId);
    return createdCategory;
  }

  Future<List<Category>> getCategories(Session session) async {
    final userId = await _getAuthenticatedUserId(session);
    return await Category.db.find(
      session,
      where: (c) => c.userId.equals(userId),
      orderBy: (c) => c.title,
    );
  }

   Future<Category?> getCategoryById(Session session, UuidValue id) async {
    final userId = await _getAuthenticatedUserId(session);
    
    return await Category.db.findFirstRow(
      session,
      where: (c) => c.id.equals(id) & c.userId.equals(userId),
    );
  }

  Future<List<Category>> getCategoriesSince(Session session, DateTime? since) async {
    final userId = await _getAuthenticatedUserId(session);
    var whereClause = (Category.t.userId.equals(userId));
    if (since != null) {
      whereClause = whereClause & (Category.t.lastModified >= since);
    }
    return await Category.db.find(
      session,
      where: (_) => whereClause,
      orderBy: (c) => c.lastModified,
    );
  }

  Future<bool> updateCategory(Session session, Category category) async {
    final userId = await _getAuthenticatedUserId(session);
    final originalCategory = await Category.db.findFirstRow(
      session,
      where: (c) => c.id.equals(category.id) & c.userId.equals(userId),
    );
    if (originalCategory == null) {
      return false; 
    }
    final serverCategory = category.copyWith(
      userId: userId,
      lastModified: DateTime.now().toUtc(),
    );
    try {
      await Category.db.updateRow(session, serverCategory);
      await _notifyChange(session, CategorySyncEvent(
        type: SyncEventType.update,
        category: serverCategory,
      ), userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(Session session, UuidValue id) async {
    final userId = await _getAuthenticatedUserId(session);
    final result = await Category.db.deleteWhere(
      session,
      where: (c) => c.id.equals(id) & c.userId.equals(userId),
    );
    if (result.isNotEmpty) {
      await _notifyChange(session, CategorySyncEvent(
        type: SyncEventType.delete,
        id: id,
      ), userId);
      return true;
    } else {
      return false;
    }
  }

  Stream<CategorySyncEvent> watchEvents(Session session) async* {
    final userId = await _getAuthenticatedUserId(session);
    final channel = '$_categoryChannelBase$userId';
    session.log('🟢 Клиент (user: $userId) подписался на события в канале "$channel"');
    try {
      await for (var event in session.messages.createStream<CategorySyncEvent>(channel)) {
        session.log('🔄 Пересылаем событие ${event.type.name} клиенту (user: $userId)');
        yield event;
      }
    } finally {
      session.log('🔴 Клиент (user: $userId) отписался от канала "$channel"');
    }
  }
}