import 'voice_assistant_platform.dart';

/// Fallback stub for non-web environments.
class VoicePlatformStub implements VoicePlatform {
  @override
  bool get isSpeechRecognitionSupported => false;

  @override
  bool get isSpeechSynthesisSupported => false;

  @override
  void startListening({
    required String language,
    required void Function(String text, bool isFinal) onResult,
    required void Function() onEnd,
    required void Function(String error) onError,
  }) {
    onError('Voice recognition is currently supported in Web / Chrome / Edge browsers.');
  }

  @override
  void stopListening() {}

  @override
  void speak({
    required String text,
    required String language,
    void Function()? onStart,
    void Function()? onEnd,
  }) {
    if (onEnd != null) {
      Future.delayed(const Duration(milliseconds: 500), onEnd);
    }
  }

  @override
  void stopSpeaking() {}
}

VoicePlatform getVoicePlatform() => VoicePlatformStub();
