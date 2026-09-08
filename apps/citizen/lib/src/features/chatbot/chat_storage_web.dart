// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'chat_storage_platform.dart';

/// Web implementation of ChatStorage using browser window.localStorage.
class ChatStorageWeb implements ChatStorage {
  static const _key = 'arogyamitra_citizen_chat_history_v1';

  @override
  Future<String?> loadHistory() async {
    try {
      return html.window.localStorage[_key];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveHistory(String jsonStr) async {
    try {
      html.window.localStorage[_key] = jsonStr;
    } catch (_) {}
  }

  @override
  Future<void> clearHistory() async {
    try {
      html.window.localStorage.remove(_key);
    } catch (_) {}
  }
}

ChatStorage getChatStorage() => ChatStorageWeb();
