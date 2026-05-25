import 'package:car_maintenance_system_new/features/chatbot/domain/repositories/chatbot_repository.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_message_entity.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_conversation_entity.dart';
import 'package:car_maintenance_system_new/features/chatbot/data/datasources/gemini_ai_datasource.dart';
import 'package:car_maintenance_system_new/features/chatbot/data/datasources/chatbot_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/chatbot/data/models/chat_message_dto.dart';

class ChatbotRepositoryImpl implements ChatbotRepository {
  final GeminiAIDatasource geminiDatasource;
  final ChatbotRemoteDatasource remoteDatasource;

  ChatbotRepositoryImpl({
    required this.geminiDatasource,
    required this.remoteDatasource,
  });

  @override
  Future<String> sendMessage(
    String userId,
    String message,
    List<ChatMessageEntity> conversationHistory, {
    String? base64Image,
    bool isTechnician = false,
  }) async {
    try {
      // Save user message
      final userMessage = ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: message,
        type: MessageType.user,
        timestamp: DateTime.now(),
        base64Image: base64Image,
      );
      await saveMessage(userId, userMessage);

      // Get AI response
      final aiResponse = await geminiDatasource.getResponse(message, conversationHistory, base64Image: base64Image, isTechnician: isTechnician);

      // Save AI response
      final assistantMessage = ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: aiResponse,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      );
      await saveMessage(userId, assistantMessage);

      return aiResponse;
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  @override
  Future<ChatConversationEntity?> getConversation(String userId) async {
    try {
      final conversationDto = await remoteDatasource.getConversation(userId);
      return conversationDto?.toEntity();
    } catch (e) {
      throw Exception('Error getting conversation: $e');
    }
  }

  @override
  Future<void> saveMessage(String userId, ChatMessageEntity message) async {
    try {
      final messageDto = ChatMessageDTO.fromEntity(message);
      await remoteDatasource.saveMessage(userId, messageDto);
    } catch (e) {
      throw Exception('Error saving message: $e');
    }
  }

  @override
  Future<void> clearConversation(String userId) async {
    try {
      await remoteDatasource.clearConversation(userId);
    } catch (e) {
      throw Exception('Error clearing conversation: $e');
    }
  }
}

