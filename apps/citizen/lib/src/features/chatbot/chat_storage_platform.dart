/// Abstract interface for persisting chat messages across sessions.
abstract class ChatStorage {
  Future<String?> loadHistory();
  Future<void> saveHistory(String jsonStr);
  Future<void> clearHistory();
}
