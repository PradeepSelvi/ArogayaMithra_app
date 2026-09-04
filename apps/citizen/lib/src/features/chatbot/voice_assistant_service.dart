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

    final lang = languageCode == 'ta' ? 'ta-IN' : 'en-IN';
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

    final lang = languageCode == 'ta' ? 'ta-IN' : 'en-IN';
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

  /// Strips markdown symbols, asterisks, hashes, list dashes, and emojis
  /// so that speech synthesis sounds natural and fluent.
  static String cleanMarkdownForSpeech(String markdown) {
    var cleaned = markdown;

    // 1. Remove horizontal rules
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-*_]{3,}\s*$', multiLine: true), ' ');

    // 2. Remove markdown header hashes
    cleaned = cleaned.replaceAll(RegExp(r'#+\s*'), '');

    // 3. Remove bold and italic asterisks / underscores
    cleaned = cleaned.replaceAll(RegExp(r'\*\*|__|\*|_'), '');

    // 4. Remove list markers like "- " or "* " or "1. "
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // 5. Remove markdown links [text](url) -> text
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[(.*?)\]\(.*?\)'),
      (match) => match.group(1) ?? '',
    );

    // 6. Remove common emojis that speech synthesizers fumble over
    cleaned = cleaned.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F018}-\u{1F270}\u{2388}]',
        unicode: true,
      ),
      '',
    );

    // 7. Normalize whitespace
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
