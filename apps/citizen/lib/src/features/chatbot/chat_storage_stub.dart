import 'chat_storage_platform.dart';

/// Non-web fallback for ChatStorage keeping messages in-memory.
class ChatStorageStub implements ChatStorage {
  static String? _inMemory;

  @override
  Future<String?> loadHistory() async => _inMemory;

  @override
  Future<void> saveHistory(String jsonStr) async {
    _inMemory = jsonStr;
  }

  @override
  Future<void> clearHistory() async {
    _inMemory = null;
  }
}

ChatStorage getChatStorage() => ChatStorageStub();
