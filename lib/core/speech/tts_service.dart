import 'package:flutter_tts/flutter_tts.dart';

/// On-device text-to-speech for the AI Search assistant — dwelleo.sa's
/// agent speaks every reply (AR/EN, following the user's language).
///
/// TTS is a progressive enhancement: any platform/voice failure is swallowed
/// so search itself never breaks because audio couldn't play.
class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text, {required bool arabic}) async {
    final t = text.trim();
    if (t.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(arabic ? 'ar-SA' : 'en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.speak(t);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
