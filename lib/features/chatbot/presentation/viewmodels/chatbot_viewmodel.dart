import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_message_entity.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/di/chatbot_usecases_di.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/usecases/send_message_usecase.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/usecases/get_conversations_usecase.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/usecases/clear_conversation_usecase.dart';

final chatbotViewModelProvider = StateNotifierProvider<ChatbotViewModel, ChatbotState>((ref) {
  final sendMessageUseCase = ref.watch(sendMessageUseCaseProvider);
  final getConversationsUseCase = ref.watch(getConversationsUseCaseProvider);
  final clearConversationUseCase = ref.watch(clearConversationUseCaseProvider);
  return ChatbotViewModel(
    sendMessageUseCase,
    getConversationsUseCase,
    clearConversationUseCase,
  );
});

class ChatbotState {
  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final File? selectedImage;

  ChatbotState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.selectedImage,
  });

  ChatbotState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    File? selectedImage,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error, // Error usually cleared unless passed
      selectedImage: selectedImage, // Usually cleared unless explicitly passed or kept via another method. Actually, to clear it, we should allow null. 
      // Workaround for nullable properties in copyWith:
    );
  }
  
  ChatbotState copyWithKeepImage({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
      selectedImage: this.selectedImage,
    );
  }
}

class ChatbotViewModel extends StateNotifier<ChatbotState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetConversationsUseCase getConversationsUseCase;
  final ClearConversationUseCase clearConversationUseCase;

  ChatbotViewModel(
    this.sendMessageUseCase,
    this.getConversationsUseCase,
    this.clearConversationUseCase,
  ) : super(ChatbotState());

  /// Load conversation history for a user
  Future<void> loadConversation(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null, selectedImage: state.selectedImage);
      final conversation = await getConversationsUseCase(userId);
      
      if (conversation != null) {
        state = state.copyWithKeepImage(
          messages: conversation.messages,
          isLoading: false,
        );
      } else {
        state = state.copyWithKeepImage(isLoading: false);
      }
    } catch (e) {
      state = state.copyWithKeepImage(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Pick an image
  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70); // Compress slightly
      
      if (pickedFile != null) {
        state = state.copyWith(
          messages: state.messages,
          isLoading: state.isLoading,
          isSending: state.isSending,
          error: state.error,
          selectedImage: File(pickedFile.path),
        );
      }
    } catch (e) {
      state = state.copyWithKeepImage(error: 'Error picking image: $e');
    }
  }

  /// Remove selected image
  void removeSelectedImage() {
    state = state.copyWith(
      messages: state.messages,
      isLoading: state.isLoading,
      isSending: state.isSending,
      error: state.error,
      selectedImage: null,
    );
  }

  /// Send a message and get AI response
  Future<void> sendMessage(String userId, String message, {bool isTechnician = false}) async {
    if (message.trim().isEmpty && state.selectedImage == null) return;

    try {
      String? base64Image;
      File? imageToSend = state.selectedImage;
      
      // Clear selected image from UI immediately while sending
      state = state.copyWith(
        isSending: true, 
        error: null,
        messages: state.messages,
        isLoading: state.isLoading,
        selectedImage: null,
      );

      if (imageToSend != null) {
        final bytes = await imageToSend.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      // Add user message to state immediately
      final userMessage = ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: message,
        type: MessageType.user,
        timestamp: DateTime.now(),
        base64Image: base64Image,
      );

      state = state.copyWithKeepImage(
        messages: [...state.messages, userMessage],
      );

      // Get AI response
      // NOTE: SendMessageUseCase needs to be updated to accept isTechnician if we want it to go all the way,
      // We already added it. Let's pass it down.
      final response = await sendMessageUseCase(userId, message, state.messages, base64Image: base64Image, isTechnician: isTechnician);

      // Add AI response to state
      final assistantMessage = ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      );

      state = state.copyWithKeepImage(
        messages: [...state.messages, assistantMessage],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWithKeepImage(
        isSending: false,
        error: e.toString(),
      );
    }
  }

  /// Clear conversation
  Future<void> clearConversation(String userId) async {
    try {
      await clearConversationUseCase(userId);
      state = state.copyWithKeepImage(messages: []);
    } catch (e) {
      state = state.copyWithKeepImage(error: e.toString());
    }
  }
}

