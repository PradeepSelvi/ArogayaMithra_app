import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Data model representing a single chat message in the conversation.
class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isEmergencyAlert = false,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isEmergencyAlert;
}

/// Mistral AI Chatbot Service for ArogyaMitra Citizen Application.
class MistralChatbotService {
  static const String _apiKey = 'rFT3tZ4BM73vqfP63fTWrKxFAjvnEt3O';
  static const String _apiUrl = 'https://api.mistral.ai/v1/chat/completions';
  static const String _model = 'mistral-small-latest';

  static const String _systemPromptEn = '''
You are ArogyaMitra AI (ஆரோக்கியமித்ரா AI), an empathetic, medically verified clinical health assistant for citizens in India, especially rural and district communities (such as Tiruvannamalai, Tamil Nadu).

YOUR ROLES & CAPABILITIES:
1. Medical Triage & Guidance: Assess patient symptoms (fever, cough, rash, stomach ache, headache, joint pain) and guide citizens to the appropriate healthcare tier:
   - Level 1: Home Care & ASHA Worker guidance
   - Level 2: Primary Health Centre (PHC) for non-emergency general medicine
   - Level 3: Community Health Centre (CHC) for maternal, pediatric, minor surgical care
   - Level 4: District Hospital (DHH) & Government Medical College Hospital (GMCH) for trauma, emergency, ICU, and super-specialty
2. Medication & Prescription Explanation: Explain standard drug usages, dosages precautions, and generic alternatives (Pradhan Mantri Jan Aushadhi).
3. Vitals Analysis: Explain readings like BP (120/80), Blood Sugar fasting/post-prandial, SpO2 (95%+), Pulse rate.
4. Government Schemes: Guide on Ayushman Bharat (AB-PMJAY), CMCHIS (Chief Minister Comprehensive Health Insurance Scheme Tamil Nadu), and ABHA Health ID.
5. First Aid: Clear, step-by-step first-aid steps for bites, burns, sprains, heat stroke.

CRITICAL EMERGENCY PROTOCOL:
If user describes red-flag emergency symptoms (severe chest pain radiating to arm, acute breathing distress, sudden paralysis/facial droop, profuse bleeding, head trauma, poisoning, severe allergic reaction):
- Begin your response with: "🚨 [EMERGENCY 108 REQUIRED]"
- Urge calling 108 immediately or visiting the nearest GMCH / District Hospital Casualty.

Tone: Warm, respectful, simple language without unnecessary medical jargon. If the user writes in Tamil, reply in Tamil (தமிழ்). If they write in English, reply in English. Always mention that AI does not replace a physical doctor's diagnosis.
''';

  final http.Client _client;

  MistralChatbotService({http.Client? client}) : _client = client ?? http.Client();

  /// Sends the conversation history plus new user message to Mistral AI and returns assistant reply.
  Future<String> sendMessage({
    required List<ChatMessage> history,
    required String userMessage,
    String languageCode = 'en',
  }) async {
    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _systemPromptEn},
      ];

      // Append up to last 8 messages for context window management
      final recentHistory = history.length > 8 ? history.sublist(history.length - 8) : history;
      for (final msg in recentHistory) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }

      // Append current message
      messages.add({'role': 'user', 'content': userMessage});

      final response = await _client.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.5,
          'max_tokens': 600,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final firstChoice = choices[0] as Map<String, dynamic>;
          final messageObj = firstChoice['message'] as Map<String, dynamic>?;
          final content = messageObj?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
        return languageCode == 'ta'
            ? 'மன்னிக்கவும், பதிலை உருவாக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.'
            : 'Sorry, I could not generate a response. Please try again.';
      } else {
        return languageCode == 'ta'
            ? 'சேவை தற்காலிகமாக கிடைக்கவில்லை (${response.statusCode}). தயவுசெய்து சிறிது நேரம் கழித்து முயற்சிக்கவும்.'
            : 'Service temporarily unavailable (${response.statusCode}). Please try again shortly.';
      }
    } catch (e) {
      return languageCode == 'ta'
          ? 'இணைப்பில் பிழை ஏற்பட்டது. உங்கள் இணைய இணைப்பை சரிபார்க்கவும்.'
          : 'Network error occurred. Please check your internet connection and try again.';
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Provider for MistralChatbotService
final mistralChatbotServiceProvider = Provider<MistralChatbotService>((ref) {
  final service = MistralChatbotService();
  ref.onDispose(service.dispose);
  return service;
});
