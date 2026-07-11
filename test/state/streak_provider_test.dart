import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushon/data/db.dart';
import 'package:pushon/data/repository.dart';
import 'package:pushon/domain/dates.dart';
import 'package:pushon/state/providers.dart';

void main() {
  // install Mon 2026-07-06, today Fri 2026-07-10.
  const install = LocalDate(2026, 7, 6);
  final today = DateTime(2026, 7, 10, 9); // Friday
  const wed = LocalDate(2026, 7, 8); // the bridging gap day

  late AppDatabase db;
  late PushOnRepository repo;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = PushOnRepository(db);
    await repo.patchSettings({'installDate': install.iso});
    // Log Mon, Tue, Thu, Fri — Wed (8th) is an unlogged gap.
    for (final d in [6, 7, 9, 10]) {
      await repo.logSet(
          date: LocalDate(2026, 7, d), count: 20, now: DateTime(2026, 7, d, 9));
    }
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => today),
    ]);
    // Teardown runs LIFO: dispose the container (cancels live subscriptions)
    // *before* closing the db, or the synchronous stream-close deadlocks
    // against the still-open subscription.
    addTearDown(() async => db.close());
    addTearDown(container.dispose);
  });

  test('rest-toggle on a bridging day re-emits the streak without a new log',
      () async {
    // A live subscription keeps the provider (and its drift stream) alive —
    // a bare `read(...future)` would let riverpod dispose it mid-load.
    final values = <int>[];
    final sub = container.listen<AsyncValue<int>>(streakProvider, (_, next) {
      final v = next.value;
      if (v != null) values.add(v);
    }, fireImmediately: true);
    addTearDown(sub.close);

    Future<void> waitFor(int want) async {
      for (var i = 0; i < 100 && (values.isEmpty || values.last != want); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    // Gap at Wed breaks the walk: only Fri + Thu count.
    await waitFor(2);
    expect(values.last, 2, reason: 'initial streak; saw $values');

    // Flag Wed as rest — changes only the transparent set, not the logged set.
    await repo.setRest(wed, true);

    // The streak must update reactively: Fri, Thu, (skip Wed), Tue, Mon = 4.
    await waitFor(4);
    expect(values.last, 4,
        reason: 'a rest toggle alone must refresh the streak; saw $values');
  });
}
