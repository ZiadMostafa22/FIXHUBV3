import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_message_entity.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_conversation_entity.dart';

abstract class ChatbotRepository {
  /// Send a message and get AI response
  Future<String> sendMessage(String userId, String message, List<ChatMessageEntity> conversationHistory, {String? base64Image, bool isTechnician = false});
  
  /// Get conversation history for a user
  Future<ChatConversationEntity?> getConversation(String userId);
  
  /// Save a message to the conversation
  Future<void> saveMessage(String userId, ChatMessageEntity message);
  
  /// Clear conversation history for a user
  Future<void> clearConversation(String userId);
}

