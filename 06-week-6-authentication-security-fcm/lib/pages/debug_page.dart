import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';

class DebugPage extends ConsumerWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushService = PushService(api: ref.read(apiClientProvider));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug FCM'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Token FCM',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: fcmTokenPreview,
            builder: (context, value, child) {
              return Text(
                value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Sumber event terakhir',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: fcmTokenSource,
            builder: (context, value, child) {
              return Text(value);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Status topik',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: fcmTopicStatus,
            builder: (context, value, child) {
              return Text(value);
            },
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              try {
                await pushService.subscribePengumuman();

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Berhasil berlangganan topik.'),
                  ),
                );
              } catch (error) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Subscribe gagal: $error'),
                  ),
                );
              }
            },
            child: const Text('Subscribe pengumuman-kampus'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              try {
                await pushService.unsubscribePengumuman();

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Berhasil berhenti berlangganan topik.'),
                  ),
                );
              } catch (error) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Unsubscribe gagal: $error'),
                  ),
                );
              }
            },
            child: const Text('Unsubscribe pengumuman-kampus'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Backend: token didaftarkan ke POST /devices.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Token FCM dikirim ke backend setelah izin diberikan '
            'dan setiap kali token berubah.',
          ),
        ],
      ),
    );
  }
}