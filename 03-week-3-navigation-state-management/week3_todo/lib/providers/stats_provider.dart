import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model kecil yang menyimpan satu baris statistik untuk ditampilkan di UI.
@immutable
class Statistic {
	const Statistic({required this.label, required this.value});

	final String label;
	final String value;
}

// Provider tunggal yang mengelola status loading, error, dan data statistik.
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<Statistic>>(
	StatsNotifier.new,
);

// AsyncNotifier menjalankan pengambilan data ketika provider pertama kali dibaca.
class StatsNotifier extends AsyncNotifier<List<Statistic>> {
	// Random dan delay dapat diganti dalam unit test agar hasilnya deterministik.
	StatsNotifier({Random? random, Duration? delay})
			: _random = random ?? Random(),
				_delay = delay ?? const Duration(seconds: 2);

	final Random _random;
	final Duration _delay;

	@override
	Future<List<Statistic>> build() async {
		// Simulasikan waktu yang dibutuhkan oleh request ke server.
		await Future<void>.delayed(_delay);

    // throw Exception('Gagal terhubung ke server');

		// Simulasikan kegagalan jaringan pada 30% kemungkinan.
		if (_random.nextDouble() < 0.3) {
			throw Exception('Data statistik gagal dimuat.');
		}

		// Data sukses selalu terdiri dari tiga statistik.
		return const [
			Statistic(label: 'Total tugas', value: '24'),
			Statistic(label: 'Tugas selesai', value: '18'),
			Statistic(label: 'Tugas tertunda', value: '6'),
		];
	}
}
