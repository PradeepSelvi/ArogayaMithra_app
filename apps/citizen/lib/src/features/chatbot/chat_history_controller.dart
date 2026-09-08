import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_storage_platform.dart';
import 'chat_storage_stub.dart' if (dart.library.html) 'chat_storage_web.dart';
import 'mistral_chatbot_service.dart';

/// State representing the persistent chat session history.
class ChatHistoryState {
  const ChatHistoryState({
    this.messages = const [],
    this.isLoading = true,
  });

  final List<ChatMessage> messages;
  final bool isLoading;

  ChatHistoryState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) =>
      ChatHistoryState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Unified Chat History controller managing persistent session messages.
class ChatHistoryController extends Notifier<ChatHistoryState> {
  late final ChatStorage _storage;

  @override
  ChatHistoryState build() {
    _storage = getChatStorage();
    _loadFromStorage();
    return const ChatHistoryState(isLoading: true);
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.loadHistory();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final loaded = decoded
              .whereType<Map<String, dynamic>>()
              .map(ChatMessage.fromJson)
              .toList();
          if (loaded.isNotEmpty) {
            state = state.copyWith(messages: loaded, isLoading: false);
            return;
          }
        }
      }
    } catch (_) {}
    state = state.copyWith(messages: const [], isLoading: false);
  }

  /// Appends a new message to the chat history and saves it to local storage.
  Future<void> addMessage(ChatMessage message) async {
    final updated = [...state.messages, message];
    state = state.copyWith(messages: updated);
    await _persist(updated);
  }

  /// Appends multiple messages to the chat history.
  Future<void> addMessages(List<ChatMessage> newMessages) async {
    final updated = [...state.messages, ...newMessages];
    state = state.copyWith(messages: updated);
    await _persist(updated);
  }

  /// Ensures an initial localized welcome greeting exists if history is completely empty.
  void ensureGreeting(String lang) {
    if (state.messages.isNotEmpty || state.isLoading) return;

    final greetingText = switch (lang) {
      'ta' =>
        'வணக்கம்! நான் ஆரோக்கியமித்ரா AI (ArogyaMitra AI). உங்கள் உடல்நலக் கேள்விகள், அறிகுறிகள், மருந்துகள், அல்லது மருத்துவமனை வழிகாட்டுதல்கள் குறித்து என்னிடம் தமிழில் அல்லது ஆங்கிலத்தில் கேளுங்கள். நான் உங்களுக்கு உதவத் தயாராக இருக்கிறேன்! 🌿',
      'hi' =>
        'नमस्ते! मैं आरोग्यमित्र AI हूँ, Groq AI द्वारा संचालित आपका निजी स्वास्थ्य सहायक। अपने लक्षणों, जांच परिणामों, दवाइयों या अस्पताल मार्गदर्शन के बारे में मुझसे हिन्दी, तमिल या अंग्रेज़ी में पूछें। मैं आपकी मदद के लिए तैयार हूँ! 🌿',
      _ =>
        'Hello! I am ArogyaMitra AI, your personal healthcare assistant powered by Groq AI. Ask me about your symptoms, lab vitals, prescriptions, or hospital guidance in Tamil, Hindi or English. How can I help you today? 🌿',
    };

    final initialGreeting = ChatMessage(text: greetingText, isUser: false);
    state = state.copyWith(messages: [initialGreeting]);
    _persist([initialGreeting]);
  }

  /// Clears the chat history with an optional new conversation greeting.
  Future<void> clearHistory([ChatMessage? initialGreeting]) async {
    final reset = initialGreeting != null ? [initialGreeting] : <ChatMessage>[];
    state = state.copyWith(messages: reset);
    if (reset.isEmpty) {
      await _storage.clearHistory();
    } else {
      await _persist(reset);
    }
  }

  Future<void> _persist(List<ChatMessage> messages) async {
    try {
      // Retain latest 80 messages in local storage for smooth performance
      final slice = messages.length > 80 ? messages.sublist(messages.length - 80) : messages;
      final encoded = jsonEncode(slice.map((m) => m.toJson()).toList());
      await _storage.saveHistory(encoded);
    } catch (_) {}
  }
}

/// Provider for ChatHistoryController.
final chatHistoryProvider =
    NotifierProvider<ChatHistoryController, ChatHistoryState>(ChatHistoryController.new);
