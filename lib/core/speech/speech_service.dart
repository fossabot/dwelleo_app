import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin facade over on-device speech recognition (speech_to_text).
///
/// INTERIM BY DESIGN: the backend voice pipeline
/// (`/user/ai/voice/conversations/process`, multipart per the handoff spec)
/// has a PENDING request/response contract, so per project rules we do not
/// code against it. On-device STT gives the site's "speak naturally" UX
/// today; when the backend contract is captured, recorded audio upload can
/// replace or augment this without UI changes.
class SpeechService {
  final stt.SpeechToText _stt;

  SpeechService([stt.SpeechToText? engine]) : _stt = engine ?? stt.SpeechToText();

  bool _initialized = false;
  bool _available = false;

  bool get isListening => _stt.isListening;

  /// Initializes once per app session; false ⇒ mic/recognition unavailable
  /// (denied permission, simulator without voices, unsupported device).
  Future<bool> ensureReady() async {
    if (_initialized) return _available;
    try {
      _available = await _stt.initialize();
    } catch (_) {
      _available = false;
    }
    _initialized = true;
    return _available;
  }

  /// Best on-device locale for the app language ('ar' / 'en'), or null to
  /// let the platform use its default.
  Future<String?> localeIdFor(String languageCode) async {
    try {
      final locales = await _stt.locales();
      final prefix = languageCode.toLowerCase();
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith(prefix)) return l.localeId;
      }
    } catch (_) {}
    return null;
  }

  /// Streams partial + final transcripts. Platform enforces its own
  /// end-of-speech timeouts; [onResult] receives (text, isFinal).
  Future<void> listen({
    String? localeId,
    required void Function(String text, bool isFinal) onResult,
  }) {
    return _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        localeId: localeId,
      ),
    );
  }

  Future<void> stop() => _stt.stop();

  Future<void> cancel() => _stt.cancel();
}
