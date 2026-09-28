import 'package:flutter/material.dart';

import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    this.onTap,
  });

  final Note note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(note.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.body.isNotEmpty)
            Text(note.body),
          if (note.dirty) ...[
            const SizedBox(height: 4),
            const Badge(
              label: Text('Belum tersinkron'),
            ),
          ],
        ],
      ),
      trailing: note.dirty
          ? const Icon(Icons.cloud_off)
          : const Icon(Icons.cloud_done),
    );
  }
}