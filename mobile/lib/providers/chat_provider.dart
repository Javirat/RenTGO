import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/chat.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<Conversation> _conversations = [];
  List<ChatMessage> _messages = [];
  bool _loading = false;

  List<Conversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  bool get loading => _loading;

  Future<Conversation> startConversation(String propertyId, String landlordId) async {
    final data = await _api.startConversation(propertyId, landlordId);
    return Conversation.fromJson(data);
  }

  Future<void> loadConversations() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _api.listConversations();
      _conversations = list.map((e) => Conversation.fromJson(e)).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String conversationId, {int page = 1, bool refresh = false}) async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _api.getMessages(conversationId, page: page);
      final msgs = list.map((e) => ChatMessage.fromJson(e)).toList();
      if (refresh || page == 1) {
        _messages = msgs;
      } else {
        _messages.addAll(msgs);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<ChatMessage> sendMessage(String conversationId, String text) async {
    final data = await _api.sendMessage(conversationId, text);
    final msg = ChatMessage.fromJson(data);
    _messages.insert(0, msg);
    notifyListeners();
    return msg;
  }
}
