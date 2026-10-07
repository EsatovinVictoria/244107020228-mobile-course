import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login berhasil',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Selamat datang di Campus Notify'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/pengumuman/1');
              },
              child: const Text('Buka Pengumuman'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                context.push('/debug');
              },
              child: const Text('Debug FCM'),
            ),
          ],
        ),
      ),
    );
  }
}