import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.sender,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'sender': sender,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        sender: json['sender'],
        text: json['text'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  static const String _storageKey = 'chat_history';

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  ChatProvider() {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      try {
        final List<dynamic> decoded = jsonDecode(stored);
        _messages = decoded.map((m) => ChatMessage.fromJson(m)).toList();
        notifyListeners();
      } catch (e) {
        _messages = [];
      }
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void addUserMessage(String text) {
    _messages.add(ChatMessage(sender: 'user', text: text));
    _saveMessages();
    notifyListeners();
  }

  void addBotMessage(String text) {
    _messages.add(ChatMessage(sender: 'bot', text: text));
    _saveMessages();
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _saveMessages();
    notifyListeners();
  }
}
