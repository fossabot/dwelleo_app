import 'package:dwelleo_app/features/properties/domain/entities/property.dart';
import 'package:dwelleo_app/features/properties/presentation/cubit/compare_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

Property _property(int id) =>
    Property(id: id, slug: 'p-$id', title: 'Property $id');

void main() {
  group('CompareCubit', () {
    test('toggle adds a property to the tray', () {
      final cubit = CompareCubit();

      cubit.toggle(_property(1));

      expect(cubit.state, hasLength(1));
      expect(cubit.contains(1), isTrue);
    });

    test('toggling the same property again removes it', () {
      final cubit = CompareCubit()..toggle(_property(1));

      cubit.toggle(_property(1));

      expect(cubit.state, isEmpty);
      expect(cubit.contains(1), isFalse);
    });

    test('the tray holds two and drops the oldest on a third', () {
      final cubit = CompareCubit()
        ..toggle(_property(1))
        ..toggle(_property(2));

      expect(cubit.isFull, isTrue);

      cubit.toggle(_property(3));

      expect(cubit.state.map((p) => p.id), [2, 3]);
    });

    test('clear empties the tray', () {
      final cubit = CompareCubit()
        ..toggle(_property(1))
        ..toggle(_property(2));

      cubit.clear();

      expect(cubit.state, isEmpty);
    });
  });
}
