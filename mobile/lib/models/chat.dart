class Conversation {
  final String id;
  final String propertyId;
  final String renterId;
  final String landlordId;
  final String propertyTitle;
  final String otherName;
  final String otherPhone;
  final String lastMessage;
  final int unreadCount;
  final DateTime lastMessageAt;

  Conversation({
    required this.id,
    required this.propertyId,
    required this.renterId,
    required this.landlordId,
    this.propertyTitle = '',
    this.otherName = '',
    this.otherPhone = '',
    this.lastMessage = '',
    this.unreadCount = 0,
    required this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      propertyId: json['property_id'] ?? '',
      renterId: json['renter_id'] ?? '',
      landlordId: json['landlord_id'] ?? '',
      propertyTitle: json['property_title'] ?? '',
      otherName: json['other_name'] ?? '',
      otherPhone: json['other_phone'] ?? '',
      lastMessage: json['last_message'] ?? '',
      unreadCount: json['unread_count'] ?? 0,
      lastMessageAt: DateTime.parse(json['last_message_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      text: json['text'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
