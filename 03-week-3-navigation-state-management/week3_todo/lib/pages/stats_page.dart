import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

// Halaman statistik yang bereaksi terhadap tiga kemungkinan AsyncValue.
class StatsPage extends ConsumerWidget {
	const StatsPage({super.key});

	@override

	Widget build(BuildContext context, WidgetRef ref) {
		// Watch membuat halaman dibangun ulang saat status provider berubah.
		final statsAsync = ref.watch(statsProvider);

		return Scaffold(
			appBar: AppBar(title: const Text('Statistik')),
			body: statsAsync.when(
				// Spinner ditampilkan selama notifier menunggu data.
				loading: () => const Center(child: CircularProgressIndicator()),
				// Error menampilkan pesan dan memulai ulang provider saat retry ditekan.
				error: (error, _) => Center(
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							Text(error.toString()),
							const SizedBox(height: 12),
							FilledButton(
								onPressed: () => ref.invalidate(statsProvider),
								child: const Text('Coba lagi'),
							),
						],
					),
				),
				// Data sukses dirender sebagai tiga baris dalam ListView.
				data: (stats) => ListView.builder(
					itemCount: stats.length,
					itemBuilder: (context, index) {
						final statistic = stats[index];
						return ListTile(
							leading: const Icon(Icons.analytics_outlined),
							title: Text(statistic.label),
							trailing: Text(
								statistic.value,
								style: Theme.of(context).textTheme.titleMedium,
							),
						);
					},
				),
			),
		);
	}
}
