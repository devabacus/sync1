import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/providers/category/category_data_providers.dart';
import '../../domain/providers/category/category_usecase_providers.dart'; // Импортируем use cases
import '../providers/category/category_state_providers.dart';
import '../../domain/entities/category/category.dart';
import '../../../../core/providers/session_manager_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _addCategoryController = TextEditingController();
  final TextEditingController _editCategoryController = TextEditingController();

  @override
  void dispose() {
    _addCategoryController.dispose();
    _editCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем, авторизован ли пользователь
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      // Пользователь не авторизован - показываем сообщение
      return Scaffold(
        appBar: AppBar(
          title: const Text('Категории'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Пожалуйста, войдите в систему',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // Теперь мы слушаем наш новый StreamProvider
    final categoriesAsyncValue = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Добавляем информацию о пользователе и кнопку выхода
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'user_info',
                enabled: false,
                child: Text(
                  currentUser.email ?? 'Пользователь',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Выйти'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.account_circle),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAddCategoryForm(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildCategoriesList(categoriesAsyncValue),
            ),
          ],
        ),
      ),
    );
  }    

 void _logout() async {
    final sessionManager = ref.read(sessionManagerProvider);
    final currentUser = ref.read(currentUserProvider); // Получаем ID пользователя ДО выхода

    await sessionManager.signOutDevice();

    if (currentUser?.id != null) {
      try {
        final categoryDao = ref.read(categoryDaoProvider); // Этот DAO не зависит от userId
        await categoryDao.deleteAllCategories(userId: currentUser!.id!);
        print('🧹 Локальные категории для пользователя ${currentUser.id} очищены.');

      } catch (e) {
        print('❌ Ошибка при очистке локальных данных пользователя ${currentUser!.id}: $e');
      }
    }
  }

  void _addCategory() async {
    final title = _addCategoryController.text.trim();
    if (title.isEmpty) {
      _showSnackBar('Введите название категории', isError: true);
      return;
    }

    // Получаем текущего пользователя
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.id == null) {
      _showSnackBar('Ошибка: пользователь не авторизован', isError: true);
      return;
    }

    final category = CategoryEntity(
      id: const Uuid().v7(),
      title: title,
      lastModified: DateTime.now().toUtc(),
      userId: currentUser!.id!, // Используем ID текущего пользователя
    );

    // Получаем use case
    final createUseCase = ref.read(createCategoryUseCaseProvider);
    if (createUseCase == null) {
      _showSnackBar('Ошибка: сервис недоступен', isError: true);
      return;
    }

    // Вызываем use case напрямую. Notifier больше не нужен.
    // UI обновится автоматически, так как use case изменит данные в БД,
    // а StreamProvider это "услышит".
    try {
      await createUseCase(category);
      _addCategoryController.clear();
      _showSnackBar('Категория добавлена');
    } catch (error) {
      _showSnackBar('Ошибка добавления: $error', isError: true);
    }
  }

  void _updateCategory(CategoryEntity category) async {
    final newTitle = _editCategoryController.text.trim();
    if (newTitle.isEmpty) {
      _showSnackBar('Введите название категории', isError: true);
      return;
    }

    if (newTitle == category.title) {
      Navigator.of(context).pop();
      return;
    }

    final updatedCategory = category.copyWith(
      title: newTitle,
      lastModified: DateTime.now().toUtc(),
    );
    
    // Получаем use case
    final updateUseCase = ref.read(updateCategoryUseCaseProvider);
    if (updateUseCase == null) {
      _showSnackBar('Ошибка: сервис недоступен', isError: true);
      return;
    }

    // Вызываем use case напрямую
    try {
      await updateUseCase(updatedCategory);
      Navigator.of(context).pop();
      _showSnackBar('Категория обновлена');
    } catch (error) {
      _showSnackBar('Ошибка обновления: $error', isError: true);
    }
  }

  void _deleteCategory(CategoryEntity category) async {
    // Получаем use case
    final deleteUseCase = ref.read(deleteCategoryUseCaseProvider);
    if (deleteUseCase == null) {
      _showSnackBar('Ошибка: сервис недоступен', isError: true);
      return;
    }

    // Вызываем use case напрямую
    try {
      await deleteUseCase(category.id);
      Navigator.of(context).pop();
      _showSnackBar('Категория удалена');
    } catch (error) {
      _showSnackBar('Ошибка удаления: $error', isError: true);
    }
  }
  
  // ----- Остальная часть файла HomePage остается без изменений -----
  // ----- (методы _buildAddCategoryForm, _buildCategoriesList, и т.д.) -----

  Widget _buildAddCategoryForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Добавить новую категорию',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCategoryController,
                    decoration: const InputDecoration(
                      hintText: 'Название категории',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
                ),
                
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(AsyncValue<List<CategoryEntity>> categoriesAsyncValue) {
    return categoriesAsyncValue.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Нет категорий',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Добавьте первую категорию',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryTile(category);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              // Вместо refresh на старый провайдер, можно просто сделать retry
              onPressed: () => ref.invalidate(categoriesStreamProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(CategoryEntity category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.category),
        ),
        title: Text(
          category.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'ID: ${category.id}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditDialog(category),
              tooltip: 'Редактировать',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteDialog(category),
              tooltip: 'Удалить',
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(CategoryEntity category) {
    _editCategoryController.text = category.title;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать категорию'),
        content: TextField(
          controller: _editCategoryController,
          decoration: const InputDecoration(
            labelText: 'Название категории',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => _updateCategory(category),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(CategoryEntity category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить категорию'),
        content: Text('Вы уверены, что хотите удалить категорию "${category.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => _deleteCategory(category),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}