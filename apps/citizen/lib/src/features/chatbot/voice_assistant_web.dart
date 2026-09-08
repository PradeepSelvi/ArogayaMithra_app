// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'voice_assistant_platform.dart';

/// Web implementation of VoicePlatform using browser Web Speech API.
///
/// Features:
/// - Continuous speech recognition with intelligent word spacing
/// - Robust error translation (filters out 'no-speech' and 'aborted')
/// - Garbage-collection protection for Chromium SpeechSynthesis
/// - Sentence-level utterance chunking for long medical responses
/// - Automatic localized voice selection for Tamil (ta-IN), Hindi (hi-IN), and English
class VoicePlatformWeb implements VoicePlatform {
  html.SpeechRecognition? _recognition;
  bool _isListening = false;

  // Retained utterance reference prevents V8 garbage-collection freezes mid-speech
  html.SpeechSynthesisUtterance? _activeUtterance;
  html.SpeechSynthesisUtterance? get activeUtterance => _activeUtterance;
  final List<String> _pendingChunks = [];
  String _currentLanguage = 'en-IN';
  void Function()? _onSpeechEnd;

  @override
  bool get isSpeechRecognitionSupported => html.SpeechRecognition.supported;

  @override
  bool get isSpeechSynthesisSupported => html.window.speechSynthesis != null;

  @override
  void startListening({
    required String language,
    required void Function(String text, bool isFinal) onResult,
    required void Function() onEnd,
    required void Function(String error) onError,
  }) {
    if (!isSpeechRecognitionSupported) {
      onError('Speech recognition is not supported in this browser. Please use Chrome, Edge, or a Web Speech-enabled browser.');
      return;
    }

    try {
      stopListening();

      _recognition = html.SpeechRecognition()
        ..continuous = true
        ..interimResults = true
        ..lang = language;

      _recognition!.onResult.listen((event) {
        final results = event.results;
        if (results == null || results.isEmpty) return;

        final buffer = StringBuffer();
        bool isFinal = false;

        for (var i = 0; i < results.length; i++) {
          final res = results[i];
          if (res.isFinal == true) isFinal = true;
          if ((res.length ?? 0) > 0) {
            final piece = res.item(0).transcript?.trim() ?? '';
            if (piece.isNotEmpty) {
              if (buffer.isNotEmpty) buffer.write(' ');
              buffer.write(piece);
            }
          }
        }

        final fullText = buffer.toString().trim();
        if (fullText.isNotEmpty) {
          onResult(fullText, isFinal);
        }
      });

      _recognition!.onEnd.listen((_) {
        _isListening = false;
        onEnd();
      });

      _recognition!.onError.listen((dynamic e) {
        _isListening = false;
        String code = '';
        try {
          code = (e as dynamic)?.error?.toString() ?? '';
        } catch (_) {
          code = e.toString();
        }

        // Harmless events: user just didn't speak within silence window or stopped listening
        if (code == 'no-speech' || code == 'aborted') {
          onEnd();
          return;
        }

        if (code == 'not-allowed' || code == 'service-not-allowed') {
          onError('Microphone permission was denied. Please allow microphone access in your browser address bar.');
          return;
        }

        if (code == 'network') {
          onError('Speech service network error. Please check your internet connection.');
          return;
        }

        onError('Speech recognition issue ($code). Please try again.');
      });

      _recognition!.start();
      _isListening = true;
    } catch (e) {
      _isListening = false;
      onError('Unable to start speech recognition: $e');
    }
  }

  @override
  void stopListening() {
    if (_recognition != null && _isListening) {
      try {
        _recognition!.stop();
      } catch (_) {}
    }
    _recognition = null;
    _isListening = false;
  }

  @override
  void speak({
    required String text,
    required String language,
    void Function()? onStart,
    void Function()? onEnd,
  }) {
    final synth = html.window.speechSynthesis;
    if (synth == null) return;

    try {
      stopSpeaking();

      _currentLanguage = language;
      _onSpeechEnd = onEnd;

      // Break long text into sentences so Chromium doesn't pause or truncate
      // after 15 seconds or 200 characters.
      final chunks = _splitIntoSpeechChunks(text);
      if (chunks.isEmpty) return;

      _pendingChunks.clear();
      _pendingChunks.addAll(chunks);

      if (onStart != null) {
        onStart();
      }

      _playNextChunk();
    } catch (_) {}
  }

  void _playNextChunk() {
    final synth = html.window.speechSynthesis;
    if (synth == null || _pendingChunks.isEmpty) {
      _activeUtterance = null;
      _onSpeechEnd?.call();
      return;
    }

    final chunkText = _pendingChunks.removeAt(0).trim();
    if (chunkText.isEmpty) {
      _playNextChunk();
      return;
    }

    final utterance = html.SpeechSynthesisUtterance(chunkText)
      ..lang = _currentLanguage
      ..rate = 0.95
      ..pitch = 1.0;

    final bestVoice = _findBestVoice(_currentLanguage);
    if (bestVoice != null) {
      utterance.voice = bestVoice;
    }

    utterance.onEnd.listen((_) {
      _playNextChunk();
    });

    utterance.onError.listen((_) {
      _playNextChunk();
    });

    // Retain globally to prevent V8 garbage collection mid-speech
    _activeUtterance = utterance;
    synth.speak(utterance);
  }

  @override
  void stopSpeaking() {
    _pendingChunks.clear();
    _activeUtterance = null;
    _onSpeechEnd = null;
    try {
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
  }

  /// Finds the best available browser synthesizer voice matching [language].
  html.SpeechSynthesisVoice? _findBestVoice(String language) {
    final synth = html.window.speechSynthesis;
    if (synth == null) return null;

    final voices = synth.getVoices();
    if (voices.isEmpty) return null;

    final normalized = language.toLowerCase().replaceAll('_', '-');

    // 1. Exact match, e.g. "ta-in", "hi-in", "en-in"
    for (final v in voices) {
      final vLang = v.lang?.toLowerCase().replaceAll('_', '-') ?? '';
      if (vLang == normalized) {
        return v;
      }
    }

    // 2. Language prefix match, e.g. "ta", "hi", "en"
    final prefix = normalized.split('-').first;
    for (final v in voices) {
      final vLang = v.lang?.toLowerCase() ?? '';
      if (vLang.startsWith(prefix)) {
        return v;
      }
    }

    return null;
  }

  /// Splits long markdown-cleaned text into small, natural sentence chunks
  /// (under 160 characters) to prevent browser TTS stalls.
  List<String> _splitIntoSpeechChunks(String text) {
    final chunks = <String>[];
    // Split by sentence delimiters: '.', '!', '?', or newline, including Devanagari danda '।'
    final rawSentences = text.split(RegExp(r'(?<=[.!?\n।])\s+'));

    for (final sentence in rawSentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.length <= 160) {
        chunks.add(trimmed);
      } else {
        // Split further by commas, semicolons, or clauses if a single sentence is very long
        final subParts = trimmed.split(RegExp(r'(?<=[,;:\-])\s+'));
        var current = '';
        for (final part in subParts) {
          if ((current.length + part.length) < 160) {
            current = current.isEmpty ? part : '$current $part';
          } else {
            if (current.isNotEmpty) chunks.add(current);
            current = part;
          }
        }
        if (current.isNotEmpty) chunks.add(current);
      }
    }

    return chunks;
  }
}

VoicePlatform getVoicePlatform() => VoicePlatformWeb();
