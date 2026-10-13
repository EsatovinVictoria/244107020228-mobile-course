import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/failures.dart';
import '../providers/announcement_provider.dart';

class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          final message = error is Failure
              ? error.message
              : 'Gagal membuka pengumuman. Silakan coba lagi.';

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    ref.invalidate(announcementProvider(id));
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        },
        data: (announcement) => Center(
          child: Text(
            'Pengumuman ID: ${announcement.id}',
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
