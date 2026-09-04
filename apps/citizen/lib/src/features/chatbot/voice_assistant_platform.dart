/// Abstract interface for platform-specific Speech-to-Text & Text-to-Speech implementations.
abstract class VoicePlatform {
  bool get isSpeechRecognitionSupported;
  bool get isSpeechSynthesisSupported;

  void startListening({
    required String language,
    required void Function(String text, bool isFinal) onResult,
    required void Function() onEnd,
    required void Function(String error) onError,
  });

  void stopListening();

  void speak({
    required String text,
    required String language,
    void Function()? onStart,
    void Function()? onEnd,
  });

  void stopSpeaking();
}
