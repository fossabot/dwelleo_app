import 'package:dwelleo_app/core/storage/recent_searches_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecentSearchesStore', () {
    test('add() persists and load() returns newest first', () async {
      final store = RecentSearchesStore();
      await store.add(const RecentSearch(tab: 0, query: 'Riyadh'));
      await store.add(const RecentSearch(tab: 2, query: 'Jeddah'));

      final loaded = await store.load();

      expect(loaded, hasLength(2));
      expect(loaded.first.query, 'Jeddah');
      expect(loaded.first.tab, 2);
      expect(loaded.last.query, 'Riyadh');
    });

    test('same query+tab is de-duplicated to the top', () async {
      final store = RecentSearchesStore();
      await store.add(const RecentSearch(tab: 0, query: 'Riyadh'));
      await store.add(const RecentSearch(tab: 0, query: 'Makkah'));
      await store.add(const RecentSearch(tab: 0, query: 'Riyadh'));

      final loaded = await store.load();

      expect(loaded.map((s) => s.query), ['Riyadh', 'Makkah']);
    });

    test('keeps at most five entries', () async {
      final store = RecentSearchesStore();
      for (var i = 0; i < 7; i++) {
        await store.add(RecentSearch(tab: 0, query: 'q$i'));
      }

      final loaded = await store.load();

      expect(loaded, hasLength(5));
      expect(loaded.first.query, 'q6');
    });

    test('survives a corrupted payload gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'recent_searches_v1': 'not-json{',
      });

      expect(await RecentSearchesStore().load(), isEmpty);
    });
  });
}
