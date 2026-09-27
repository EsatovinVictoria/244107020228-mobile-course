import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

final lastOpenedProvider = FutureProvider<String?>((ref) {
  return ref.watch(prefsRepositoryProvider).getLastOpened();
});

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    final lastOpened = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Mode Gelap'),
            subtitle: const Text('Aktifkan tema gelap aplikasi'),
            value: darkMode.value ?? false,
            onChanged: darkMode.isLoading
                ? null
                : (_) {
                    ref.read(darkModeProvider.notifier).toggle();
                  },
          ),
          ListTile(
            title: const Text('Terakhir Dibuka'),
            subtitle: lastOpened.when(
              loading: () => const Text('Memuat...'),
              error: (error, _) => Text('Error: $error'),
              data: (value) => Text(value ?? 'Belum ada data'),
            ),
          ),
        ],
      ),
    );
  }
}