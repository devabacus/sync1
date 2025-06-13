
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:sync1_client/sync1_client.dart';

// var client = Client('https://api5.my-points.ru/')
var client = Client('http://localhost:8080/')
  ..connectivityMonitor = FlutterConnectivityMonitor();

class ServerCheckUi extends StatefulWidget {
  const ServerCheckUi({super.key});

  @override
  State<ServerCheckUi> createState() => _ServerCheckUiState();
}

class _ServerCheckUiState extends State<ServerCheckUi> {
  final TextEditingController _titleController = TextEditingController();
  List<TestData> _items = [];
  bool _isLoading = false;

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  /// Получает список всех записей с сервера
  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      // Вызываем client.testData.listTestDatas()
      final items = await client.testData.listTestDatas();
      setState(() {
        _items = items;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to fetch items: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Создает новую запись
  Future<void> _createItem() async {
    if (_titleController.text.isEmpty) {
      _showErrorSnackBar('Title cannot be empty');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final newUuid = UuidValue.fromString(_uuid.v7());
      
      // Создаем объект TestData
      final newItem = TestData(
        id: newUuid, 
        title: _titleController.text
      );
      
      // Вызываем client.testData.createTestData()
      await client.testData.createTestData(newItem);
      _titleController.clear();
      await _fetchItems();
    } catch (e) {
      _showErrorSnackBar('Failed to create item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Обновляет запись
  Future<void> _updateItem(TestData item, String newTitle) async {
    setState(() => _isLoading = true);
    try {
      final updatedItem = TestData(id: item.id, title: newTitle);
      // Вызываем client.testData.updateTestData()
      await client.testData.updateTestData(updatedItem);
      await _fetchItems();
    } catch (e) {
      _showErrorSnackBar('Failed to update item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Удаляет запись
  Future<void> _deleteItem(TestData item) async {
    setState(() => _isLoading = true);
    try {
      // Вызываем client.testData.deleteTestData()
      await client.testData.deleteTestData(item);
      await _fetchItems();
    } catch (e) {
      _showErrorSnackBar('Failed to delete item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(TestData item) {
    final editController = TextEditingController(text: item.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Entry'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.isNotEmpty) {
                _updateItem(item, editController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TestData Entries'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Entry Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createItem,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text('ID: ${item.id?.uuid ?? "N/A"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteItem(item),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
