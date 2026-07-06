import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/secure_storage.dart';

/// Owns the app's [ThemeMode] (light / dark / system) and persists the choice.
/// The website exposes a sun/moon toggle in its app bar; this backs the same
/// control in the app.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._storage) : super(ThemeMode.system);

  final SecureStorage _storage;

  Future<void> init() async {
    final stored = await _storage.getThemeMode();
    emit(_fromString(stored));
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await _storage.setThemeMode(mode.name);
  }

  /// Sun/moon toggle. Requires the caller to supply whether the device is
  /// currently dark (effective brightness), so toggling from ThemeMode.system
  /// on a dark device correctly moves to explicit light instead of dark.
  Future<void> toggle({required bool currentlyDark}) =>
      setMode(currentlyDark ? ThemeMode.light : ThemeMode.dark);

  bool get isDark => state == ThemeMode.dark;

  static ThemeMode _fromString(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
