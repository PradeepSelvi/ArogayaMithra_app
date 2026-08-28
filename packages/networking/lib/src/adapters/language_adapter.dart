import 'dart:typed_data';

import 'package:am_core/am_core.dart';
import 'package:am_models/am_models.dart';

/// A speech-to-text result.
class TranscriptionResult {
  const TranscriptionResult({
    required this.text,
    required this.language,
    this.confidence,
    this.isMock = true,
  });

  final String text;
  final LanguageCode language;
  final double? confidence;
  final bool isMock;
}

/// Language and voice services, fronting Bhashini (PRD 14.2).
///
/// Two rules shape this contract:
///   * Audio is never persisted by ArogyaMitra. Buffers are passed through and
///     discarded, because the platform has no retention basis for voice
///     recordings (PRD 14.2).
///   * Transcription output is treated as *input assistance only*. It is mapped
///     onto symptom codes and confirmed by the user before triage runs, so a
///     mis-hearing can never silently change a clinical outcome (PRD 20).
abstract interface class LanguageAdapter {
  /// Transcribes spoken input.
  Future<Result<TranscriptionResult>> transcribe({
    required Uint8List audio,
    required LanguageCode language,
  });

  /// Synthesises speech for accessible responses (PRD 5.1).
  Future<Result<Uint8List>> synthesise({
    required String text,
    required LanguageCode language,
  });

  /// Translates between supported languages.
  Future<Result<String>> translate({
    required String text,
    required LanguageCode from,
    required LanguageCode to,
  });

  /// Maps free spoken text onto known symptom codes.
  ///
  /// Returns candidates for the user to confirm. It deliberately does not return
  /// a triage decision.
  Future<Result<List<String>>> extractSymptomCodes({
    required String text,
    required LanguageCode language,
    required List<Symptom> catalogue,
  });
}

/// Development adapter with no network calls.
///
/// Keyword matching against the localised symptom catalogue is enough to build
/// and test the voice-assisted journey end to end; swapping in the Bhashini
/// transport later does not change any caller.
final class MockLanguageAdapter implements LanguageAdapter {
  const MockLanguageAdapter();

  @override
  Future<Result<TranscriptionResult>> transcribe({
    required Uint8List audio,
    required LanguageCode language,
  }) async {
    if (audio.isEmpty) {
      return const Err(
        Failure(
          kind: FailureKind.invalidInput,
          messageKey: 'error.no_audio_captured',
        ),
      );
    }

    // A deterministic stand-in. Real transcription arrives with the Bhashini
    // adapter; the shape of the result is what matters for the workflow.
    return Success(
      TranscriptionResult(
        text: language == LanguageCode.tamil
            ? 'எனக்கு காய்ச்சல் மற்றும் இருமல் உள்ளது'
            : 'I have fever and cough',
        language: language,
        confidence: 0.82,
      ),
    );
  }

  @override
  Future<Result<Uint8List>> synthesise({
    required String text,
    required LanguageCode language,
  }) async =>
      // No audio is produced offline. Callers fall back to on-screen text, so
      // the accessible path degrades rather than breaking (PRD 27).
      const Err(
        Failure(
          kind: FailureKind.integration,
          messageKey: 'error.tts_unavailable',
          isRetryable: false,
        ),
      );

  @override
  Future<Result<String>> translate({
    required String text,
    required LanguageCode from,
    required LanguageCode to,
  }) async =>
      Success(text);

  @override
  Future<Result<List<String>>> extractSymptomCodes({
    required String text,
    required LanguageCode language,
    required List<Symptom> catalogue,
  }) async {
    final haystack = text.toLowerCase();
    final matches = <String>[];

    for (final symptom in catalogue) {
      final tamil = symptom.nameTa.toLowerCase();
      final english = symptom.nameEn.toLowerCase();

      if (haystack.contains(tamil) || haystack.contains(english)) {
        matches.add(symptom.code);
      }
    }

    return Success(matches);
  }
}
