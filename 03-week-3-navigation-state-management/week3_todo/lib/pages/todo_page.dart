import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ToDo Riverpod')),
      body: todos.isEmpty 
        ? const Center(child: Text('Belum Ada Tugas!'))
        : ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) => ListTile(
            leading : Checkbox(
              value: todos[index].done,
              onChanged: (_) =>
                ref.read(todoListProvider.notifier).toggle(index),
            ),
            title: Text(
              todos[index].title,
              style: TextStyle(
                decoration: todos[index].done
                  ? TextDecoration.lineThrough : null
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => ref.read(todoListProvider.notifier).remove(index),
            ),
          ),
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