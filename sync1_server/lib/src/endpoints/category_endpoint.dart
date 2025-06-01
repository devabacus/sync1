import 'package:serverpod/serverpod.dart';
import 'package:sync1_server/src/generated/protocol.dart';

class CategoryEndpoint extends Endpoint {
  Future<Category> createCategory(Session session, Category category) async {
    await Category.db.insertRow(session, category);
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
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
