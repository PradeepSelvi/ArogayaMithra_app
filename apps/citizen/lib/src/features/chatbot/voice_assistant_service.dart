import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_assistant_platform.dart';
import 'voice_assistant_stub.dart' if (dart.library.html) 'voice_assistant_web.dart';

/// Unified Voice Assistant Service managing Speech-to-Text & Text-to-Speech.
class VoiceAssistantService extends ChangeNotifier {
  VoiceAssistantService() {
    _platform = getVoicePlatform();
  }

  late final VoicePlatform _platform;

  bool _isListening = false;
  bool _isSpeaking = false;
  String _liveTranscript = '';
  String? _currentlySpeakingText;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get liveTranscript => _liveTranscript;
  String? get currentlySpeakingText => _currentlySpeakingText;
  bool get isSpeechRecognitionSupported => _platform.isSpeechRecognitionSupported;
  bool get isSpeechSynthesisSupported => _platform.isSpeechSynthesisSupported;

  /// Starts listening to microphone and transcribing user speech in real-time.
  void startListening({
    required String languageCode,
    required void Function(String text, bool isFinal) onResult,
    void Function()? onEnd,
    void Function(String error)? onError,
  }) {
    stopSpeaking(); // Silence any audio when user starts speaking

    final lang = _bcp47(languageCode);
    _isListening = true;
    _liveTranscript = '';
    notifyListeners();

    _platform.startListening(
      language: lang,
      onResult: (text, isFinal) {
        _liveTranscript = text;
        notifyListeners();
        onResult(text, isFinal);
      },
      onEnd: () {
        _isListening = false;
        notifyListeners();
        if (onEnd != null) onEnd();
      },
      onError: (err) {
        _isListening = false;
        notifyListeners();
        if (onError != null) onError(err);
      },
    );
  }

  /// Stops active microphone recording.
  void stopListening() {
    _platform.stopListening();
    _isListening = false;
    notifyListeners();
  }

  /// Cleans markdown and speaks the text aloud in the requested language.
  void speak({
    required String text,
    required String languageCode,
    void Function()? onStart,
    void Function()? onEnd,
  }) {
    stopListening(); // Don't record own output

    final cleanText = cleanMarkdownForSpeech(text);
    if (cleanText.isEmpty) return;

    final lang = _bcp47(languageCode);
    _isSpeaking = true;
    _currentlySpeakingText = text;
    notifyListeners();

    _platform.speak(
      text: cleanText,
      language: lang,
      onStart: () {
        _isSpeaking = true;
        notifyListeners();
        if (onStart != null) onStart();
      },
      onEnd: () {
        _isSpeaking = false;
        _currentlySpeakingText = null;
        notifyListeners();
        if (onEnd != null) onEnd();
      },
    );
  }

  /// Halts speech playback immediately.
  void stopSpeaking() {
    _platform.stopSpeaking();
    _isSpeaking = false;
    _currentlySpeakingText = null;
    notifyListeners();
  }

  /// Detects whether [text] is written in Tamil or Hindi (Devanagari) script.
  ///
  /// Speech synthesis must match the language the text is actually written
  /// in, not the app's UI language toggle: an assistant reply can end up in
  /// a different language than the current toggle (e.g. it answered an
  /// older question before the citizen switched languages), and reading
  /// English text aloud with a Tamil or Hindi voice (or vice versa) comes
  /// out garbled.
  static String detectLanguageOfText(String text) {
    if (RegExp(r'[\u{0B80}-\u{0BFF}]', unicode: true).hasMatch(text)) return 'ta';
    if (RegExp(r'[\u{0900}-\u{097F}]', unicode: true).hasMatch(text)) return 'hi';
    return 'en';
  }

  /// BCP-47 tag for speech recognition/synthesis engines.
  static String _bcp47(String languageCode) => switch (languageCode) {
        'ta' => 'ta-IN',
        'hi' => 'hi-IN',
        _ => 'en-IN',
      };

  /// Strips markdown symbols, asterisks, hashes, list dashes, and emojis
  /// so that speech synthesis sounds natural and fluent.
  static String cleanMarkdownForSpeech(String markdown) {
    var cleaned = markdown;

    // 1. Remove markdown table header separator rows like |---|---|
    cleaned = cleaned.replaceAll(RegExp(r'\|(?:\s*:?-+:?\s*\|)+', multiLine: true), ' ');

    // 2. Remove table pipes | replacing with a natural pause
    cleaned = cleaned.replaceAll('|', ', ');

    // 3. Replace <br> or <br/> tags with a sentence pause
    cleaned = cleaned.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '. ');

    // 4. Strip any other HTML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), ' ');

    // 5. Remove horizontal rules
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-*_]{3,}\s*$', multiLine: true), ' ');

    // 6. Remove markdown header hashes
    cleaned = cleaned.replaceAll(RegExp(r'#+\s*'), '');

    // 7. Remove bold and italic asterisks / underscores
    cleaned = cleaned.replaceAll(RegExp(r'\*\*|__|\*|_'), '');

    // 8. Remove list markers like "- " or "* " or "1. "
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // 9. Remove markdown links [text](url) -> text
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[(.*?)\]\(.*?\)'),
      (match) => match.group(1) ?? '',
    );

    // 10. Remove common emojis that speech synthesizers fumble over
    cleaned = cleaned.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F018}-\u{1F270}\u{2388}]',
        unicode: true,
      ),
      '',
    );

    // 11. Normalize duplicate punctuation (e.g. ", ,") and whitespace
    cleaned = cleaned.replaceAll(RegExp(r',\s*,'), ',');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }
}

/// Provider for VoiceAssistantService.
final voiceAssistantServiceProvider = ChangeNotifierProvider<VoiceAssistantService>((ref) {
  final service = VoiceAssistantService();
  ref.onDispose(service.dispose);
  return service;
});
