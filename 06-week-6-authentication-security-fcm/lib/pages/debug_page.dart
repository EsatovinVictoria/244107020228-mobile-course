import 'package:flutter/material.dart';

import '../messaging/push_service.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                await subscribePengumuman();

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
                await unsubscribePengumuman();

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
            'Backend: belum dikonfigurasi.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Token sudah dapat diperiksa di aplikasi. '
            'Pengiriman dan penyimpanan token di backend '
            'belum dilakukan.',
          ),
        ],
      ),
    );
  }
}