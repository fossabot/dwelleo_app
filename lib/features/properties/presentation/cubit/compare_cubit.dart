import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/property.dart';

/// dwelleo.sa's Compare feature, mobile-sized: an app-wide tray holding up
/// to TWO properties (registered as a singleton in DI so every screen sees
/// the same tray). Purely local state over already-fetched verified data.
class CompareCubit extends Cubit<List<Property>> {
  CompareCubit() : super(const []);

  static const int capacity = 2;

  bool contains(int propertyId) => state.any((p) => p.id == propertyId);

  bool get isFull => state.length >= capacity;

  /// Adds (or removes when already present). When the tray is full, the
  /// OLDEST entry is replaced — matching "compare with something else".
  void toggle(Property property) {
    if (contains(property.id)) {
      emit(List.unmodifiable(state.where((p) => p.id != property.id)));
      return;
    }
    final next = [...state, property];
    if (next.length > capacity) next.removeAt(0);
    emit(List.unmodifiable(next));
  }

  void remove(int propertyId) =>
      emit(List.unmodifiable(state.where((p) => p.id != propertyId)));

  void clear() => emit(const []);
}
