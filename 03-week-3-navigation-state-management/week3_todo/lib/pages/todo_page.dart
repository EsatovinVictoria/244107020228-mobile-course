import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);

    final uncompletedTodos = ref.watch(uncompletedTodoListProvider);

    return Scaffold(
      appBar: AppBar(title: Text('ToDo (${uncompletedTodos.length} belum selesai)')),
      body: todos.isEmpty
          ? const Center(child: Text('Belum Ada Tugas!'))
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                
                // 🟢 Menggunakan widget TodoTile yang sudah diekstrak
                return TodoTile(
                  title: todo.title,
                  isDone: todo.done,
                  onToggle: () =>
                      ref.read(todoListProvider.notifier).toggle(index),
                  onDelete: () =>
                      ref.read(todoListProvider.notifier).remove(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas Baru'),
        content: TextField(controller: controller, autofocus: true,),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                  .read(todoListProvider.notifier)
                  .add(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}