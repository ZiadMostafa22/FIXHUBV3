enum MessageType {
  user,
  assistant,
}

class ChatMessageEntity {
  final String id;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final String? base64Image;

  ChatMessageEntity({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    this.base64Image,
  });

  ChatMessageEntity copyWith({
    String? id,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    String? base64Image,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      base64Image: base64Image ?? this.base64Image,
    );
  }
}

