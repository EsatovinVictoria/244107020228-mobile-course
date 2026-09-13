import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/providers/stats_provider.dart';

// Random palsu membuat cabang sukses dan gagal dapat diuji tanpa flaky test.
class FixedRandom implements Random {
	FixedRandom(this.result);

	final double result;

	@override
	double nextDouble() => result;

	@override
	bool nextBool() => result >= 0.5;

	@override
	int nextInt(int max) => result >= 0.5 ? max - 1 : 0;
}

void main() {
	test('notifier mengembalikan tiga statistik saat request sukses', () async {
		final container = ProviderContainer(
			overrides: [
				statsProvider.overrideWith(
					() => StatsNotifier(
						random: FixedRandom(0.9),
						delay: Duration.zero,
					),
				),
			],
		);
		addTearDown(container.dispose);

		final stats = await container.read(statsProvider.future);

		expect(stats, hasLength(3));
		expect(stats.first.label, 'Total tugas');
	});

	test('notifier menghasilkan error saat simulasi request gagal', () async {
		final container = ProviderContainer(
			overrides: [
				statsProvider.overrideWith(
					() => StatsNotifier(
						random: FixedRandom(0.1),
						delay: Duration.zero,
					),
				),
			],
		);
		addTearDown(container.dispose);

		await expectLater(
			container.read(statsProvider.future),
			throwsA(isA<Exception>()),
		);
	});
}
