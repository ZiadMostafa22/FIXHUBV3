import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_message_entity.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/repositories/chatbot_repository.dart';

class SendMessageUseCase {
  final ChatbotRepository repository;

  SendMessageUseCase(this.repository);

  Future<String> call(String userId, String message, List<ChatMessageEntity> conversationHistory, {String? base64Image, bool isTechnician = false}) async {
    return await repository.sendMessage(userId, message, conversationHistory, base64Image: base64Image, isTechnician: isTechnician);
  }
}

