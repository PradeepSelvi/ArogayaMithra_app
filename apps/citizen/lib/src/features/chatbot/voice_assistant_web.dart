// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'voice_assistant_platform.dart';

/// Web implementation of VoicePlatform using browser Web Speech API.
class VoicePlatformWeb implements VoicePlatform {
  html.SpeechRecognition? _recognition;
  bool _isListening = false;

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
      onError('Speech recognition not supported in this browser.');
      return;
    }

    try {
      stopListening();

      _recognition = html.SpeechRecognition()
        ..continuous = false
        ..interimResults = true
        ..lang = language;

      _recognition!.onResult.listen((event) {
        final results = event.results;
        if (results == null || results.isEmpty) return;

        String transcript = '';
        bool isFinal = false;

        for (var i = 0; i < results.length; i++) {
          final res = results[i];
          if (res.isFinal == true) isFinal = true;
          if ((res.length ?? 0) > 0) {
            transcript += res.item(0).transcript ?? '';
          }
        }

        onResult(transcript.trim(), isFinal);
      });

      _recognition!.onEnd.listen((_) {
        _isListening = false;
        onEnd();
      });

      _recognition!.onError.listen((e) {
        _isListening = false;
        onError(e.toString());
      });

      _recognition!.start();
      _isListening = true;
    } catch (e) {
      _isListening = false;
      onError(e.toString());
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
      synth.cancel(); // Cancel any existing speaking

      final utterance = html.SpeechSynthesisUtterance(text)
        ..lang = language
        ..rate = 0.95
        ..pitch = 1.0;

      if (onStart != null) {
        utterance.onStart.listen((_) => onStart());
      }
      if (onEnd != null) {
        utterance.onEnd.listen((_) => onEnd());
      }

      synth.speak(utterance);
    } catch (_) {}
  }

  @override
  void stopSpeaking() {
    try {
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
  }
}

VoicePlatform getVoicePlatform() => VoicePlatformWeb();
