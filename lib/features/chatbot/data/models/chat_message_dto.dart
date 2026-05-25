import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_message_entity.dart';

class ChatMessageDTO {
  final String id;
  final String text;
  final String type; // 'user' or 'assistant'
  final Timestamp timestamp;
  final String? base64Image;

  ChatMessageDTO({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    this.base64Image,
  });

  // Convert to Entity
  ChatMessageEntity toEntity() {
    return ChatMessageEntity(
      id: id,
      text: text,
      type: type == 'user' ? MessageType.user : MessageType.assistant,
      timestamp: timestamp.toDate(),
      base64Image: base64Image,
    );
  }

  // Convert from Entity
  factory ChatMessageDTO.fromEntity(ChatMessageEntity entity) {
    return ChatMessageDTO(
      id: entity.id,
      text: entity.text,
      type: entity.type == MessageType.user ? 'user' : 'assistant',
      timestamp: Timestamp.fromDate(entity.timestamp),
      base64Image: entity.base64Image,
    );
  }

  // Convert from Firestore
  factory ChatMessageDTO.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatMessageDTO(
      id: id,
      text: data['text'] ?? '',
      type: data['type'] ?? 'user',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      base64Image: data['base64Image'],
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    final map = {
      'text': text,
      'type': type,
      'timestamp': timestamp,
    };
    if (base64Image != null) {
      map['base64Image'] = base64Image!;
    }
    return map;
  }
}

