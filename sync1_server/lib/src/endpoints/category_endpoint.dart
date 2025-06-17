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

  // 1. ПРОВЕРКА: Ищем, существует ли уже запись с таким ID
  final existingCategory = await Category.db.findFirstRow(
    session,
    where: (c) => c.id.equals(category.id) & c.userId.equals(userId),
  );

  final serverCategory = category.copyWith(
      userId: userId,
      lastModified: DateTime.now().toUtc(),
      isDeleted: false,
  );

  // 2. УСЛОВИЕ: в зависимости от того, найдена ли запись
  if (existingCategory != null) {
    // 3. ОБНОВЛЕНИЕ (Воскрешение): Если запись найдена, обновляем ее
    session.log('ℹ️ "createCategory" вызван для существующего ID. Выполняется обновление (воскрешение).');
    final updatedCategory = await Category.db.updateRow(session, serverCategory);

    // Уведомляем клиентов об ИЗМЕНЕНИИ (update), а не о создании
    await _notifyChange(session, CategorySyncEvent(
        type: SyncEventType.update, // Отправляем правильный тип события
        category: updatedCategory,
    ), userId);
    return updatedCategory;

  } else {
    // 4. СОЗДАНИЕ: Если запись не найдена, создаем новую
    final createdCategory = await Category.db.insertRow(session, serverCategory);
    await _notifyChange(session, CategorySyncEvent(
        type: SyncEventType.create,
        category: createdCategory,
    ), userId);
    return createdCategory;
  }
}

  // ИЗМЕНЕНО: Теперь возвращает только НЕ удаленные записи
  Future<List<Category>> getCategories(Session session) async {
    final userId = await _getAuthenticatedUserId(session);
    return await Category.db.find(
      session,
      // Добавляем фильтр isDeleted == false
      where: (c) => c.userId.equals(userId) & c.isDeleted.equals(false),
      orderBy: (c) => c.title,
    );
  }

   Future<Category?> getCategoryById(Session session, UuidValue id) async {
    final userId = await _getAuthenticatedUserId(session);
    
    return await Category.db.findFirstRow(
      session,
      where: (c) => c.id.equals(id) & c.userId.equals(userId) & c.isDeleted.equals(false),
    );
  }

  // ИЗМЕНЕНО: Теперь возвращает ВСЕ измененные записи, включая "надгробия"
  Future<List<Category>> getCategoriesSince(Session session, DateTime? since) async {
    final userId = await _getAuthenticatedUserId(session);
    // Если since не указан, возвращаем только активные записи (для первой синхронизации)
    if (since == null) {
      return getCategories(session);
    }

    // Если since указан, возвращаем ВСЕ, что было изменено, включая удаленные
    return await Category.db.find(
      session,
      where: (c) => c.userId.equals(userId) & (c.lastModified >= since),
      orderBy: (c) => c.lastModified,
    );
  }

  Future<bool> updateCategory(Session session, Category category) async {
    final userId = await _getAuthenticatedUserId(session);
    final originalCategory = await Category.db.findFirstRow(
      session,
      where: (c) => c.id.equals(category.id) & c.userId.equals(userId) & c.isDeleted.equals(false),
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

  // ИЗМЕНЕНО: Теперь не удаляет, а ставит флаг isDeleted = true
  Future<bool> deleteCategory(Session session, UuidValue id) async {
    final userId = await _getAuthenticatedUserId(session);
    
    // Находим оригинальную запись
    final originalCategory = await Category.db.findFirstRow(
      session,
      where: (c) => c.id.equals(id) & c.userId.equals(userId),
    );

    if (originalCategory == null) return false;

    // Создаем "надгробие"
    final tombstone = originalCategory.copyWith(
      isDeleted: true,
      lastModified: DateTime.now().toUtc(),
    );

    // Обновляем запись
    final result = await Category.db.updateRow(session, tombstone);

    // Отправляем событие об УДАЛЕНИИ, но с полной записью-"надгробием"
    await _notifyChange(session, CategorySyncEvent(
      type: SyncEventType.delete,
      category: result, // Отправляем "надгробие"
      id: id,
    ), userId);

    return true;
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