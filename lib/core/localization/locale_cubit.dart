import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/secure_storage.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._storage) : super(const Locale('en'));

  final SecureStorage _storage;

  Future<void> init() async {
    final stored = await _storage.getLocale();
    if (stored != null) emit(Locale(stored));
  }

  Future<void> setLocale(String languageCode) async {
    await _storage.setLocale(languageCode);
    emit(Locale(languageCode));
  }
}
