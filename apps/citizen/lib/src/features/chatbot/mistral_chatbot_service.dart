import 'package:am_networking/am_networking.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'isEmergencyAlert': isEmergencyAlert,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        isEmergencyAlert: json['isEmergencyAlert'] as bool? ?? false,
      );
}

/// A tool the assistant can ask the app to run instead of replying in text,
/// e.g. navigating to a specific in-app screen.
enum ChatTool {
  openAmbulanceTracker,
  openFacilityMap,
  openMedications,
  openVitalsTracker,
  openLabVault,
  openReferrals,
  openProfile,
  openHomeVisitRequest;

  static ChatTool? fromWire(String? wire) => switch (wire) {
        'open_ambulance_tracker' => ChatTool.openAmbulanceTracker,
        'open_facility_map' => ChatTool.openFacilityMap,
        'open_medications' => ChatTool.openMedications,
        'open_vitals_tracker' => ChatTool.openVitalsTracker,
        'open_lab_vault' => ChatTool.openLabVault,
        'open_referrals' => ChatTool.openReferrals,
        'open_profile' => ChatTool.openProfile,
        'open_home_visit_request' => ChatTool.openHomeVisitRequest,
        _ => null,
      };
}

/// The assistant's reply: either text to show, or a tool the app should run.
class ChatReply {
  const ChatReply.text(this.content) : tool = null;
  const ChatReply.tool(this.tool) : content = null;

  final String? content;
  final ChatTool? tool;
}

/// Healthcare chatbot service for ArogyaMitra Citizen, backed by the
/// `chat-completion` Supabase Edge Function.
///
/// The Mistral API key must never live in client code: an earlier version of
/// this file called Mistral directly with the key hardcoded here, and once
/// that key was committed to a public repository it was scraped and abused
/// within days, exhausting its quota for every citizen using the app. The
/// key now lives only as a server-side secret on the Edge Function, and this
/// service just calls that function over the citizen's authenticated
/// Supabase session.
class MistralChatbotService {
  MistralChatbotService(this._client);

  final SupabaseClient _client;

  /// Sends the conversation history plus new user message and returns the
  /// assistant's reply, which may be a tool call instead of text.
  Future<ChatReply> sendMessage({
    required List<ChatMessage> history,
    required String userMessage,
    String languageCode = 'en',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'chat-completion',
        body: {
          'history': history
              .map((msg) => {'text': msg.text, 'isUser': msg.isUser})
              .toList(),
          'userMessage': userMessage,
          'languageCode': languageCode,
        },
      );

      final data = response.data;
      if (data is Map) {
        final tool = ChatTool.fromWire(data['toolCall'] as String?);
        if (tool != null) return ChatReply.tool(tool);

        final content = (data['content'] as String?)?.trim();
        if (content != null && content.isNotEmpty) {
          return ChatReply.text(content);
        }
      }

      return ChatReply.text(_couldNotGenerate(languageCode));
    } catch (e, st) {
      debugPrint('MistralChatbotService.sendMessage error: $e\n$st');
      return ChatReply.text(_serviceUnavailable(languageCode));
    }
  }

  static String _couldNotGenerate(String languageCode) => switch (languageCode) {
        'ta' => 'மன்னிக்கவும், பதிலை உருவாக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
        'hi' => 'क्षमा करें, उत्तर तैयार नहीं हो सका। कृपया फिर से कोशिश करें।',
        _ => 'Sorry, I could not generate a response. Please try again.',
      };

  static String _serviceUnavailable(String languageCode) => switch (languageCode) {
        'ta' => 'சேவை தற்காலிகமாக கிடைக்கவில்லை. தயவுசெய்து சிறிது நேரம் கழித்து முயற்சிக்கவும்.',
        'hi' => 'सेवा अभी अस्थायी रूप से उपलब्ध नहीं है। कृपया थोड़ी देर बाद फिर से कोशिश करें।',
        _ => 'Service temporarily unavailable. Please try again shortly.',
      };
}

/// Provider for MistralChatbotService
final mistralChatbotServiceProvider = Provider<MistralChatbotService>((ref) {
  return MistralChatbotService(ref.watch(supabaseClientProvider));
});
