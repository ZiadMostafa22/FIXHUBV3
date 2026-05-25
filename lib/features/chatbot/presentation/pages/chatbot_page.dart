import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car_maintenance_system_new/features/chatbot/presentation/viewmodels/chatbot_viewmodel.dart';
import 'package:car_maintenance_system_new/features/chatbot/presentation/widgets/chat_message_bubble.dart';
import 'package:car_maintenance_system_new/features/chatbot/presentation/widgets/chat_input_field.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:car_maintenance_system_new/core/localization/app_localizations.dart';

class ChatbotPage extends ConsumerStatefulWidget {
  const ChatbotPage({super.key});

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversation();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadConversation() {
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      ref.read(chatbotViewModelProvider.notifier).loadConversation(user.id);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatbotState = ref.watch(chatbotViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F170F) : Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'chatbot_title'.tr(ref),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'online_now'.tr(ref),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.normal,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (chatbotState.messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 24.sp),
              onPressed: () {
                if (user != null) {
                  ref.read(chatbotViewModelProvider.notifier)
                      .clearConversation(user.id);
                }
              },
              tooltip: 'clear_conversation'.tr(ref),
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: chatbotState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatbotState.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80.w,
                              height: 80.w,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 48.sp,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              user?.role == 'technician' ? 'tech_chatbot_welcome'.tr(ref) : 'customer_chatbot_welcome'.tr(ref),
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey[300] : Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32.w),
                              child: Text(
                                user?.role == 'technician' 
                                    ? 'tech_chatbot_hint'.tr(ref) 
                                    : 'customer_chatbot_hint'.tr(ref),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        color: isDark ? const Color(0xFF0F170F) : Colors.grey[50],
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                          itemCount: chatbotState.messages.length,
                          itemBuilder: (context, index) {
                            return ChatMessageBubble(
                              message: chatbotState.messages[index],
                            );
                          },
                        ),
                      ),
          ),
          // Error message
          if (chatbotState.error != null)
            Container(
              padding: EdgeInsets.all(8.w),
              color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red[50],
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: isDark ? Colors.redAccent : Colors.red[700], size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      chatbotState.error!,
                      style: TextStyle(
                        color: isDark ? Colors.redAccent : Colors.red[700],
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Input Field
          ChatInputField(
            onSend: (message) {
              if (user != null) {
                // Determine if user is technician
                final isTechnician = ref.read(authViewModelProvider).userRole == 'technician';
                ref.read(chatbotViewModelProvider.notifier)
                    .sendMessage(user.id, message, isTechnician: isTechnician);
              }
            },
            isLoading: chatbotState.isSending,
            selectedImage: chatbotState.selectedImage,
            onCameraTap: user?.role == 'technician' ? () {
              ref.read(chatbotViewModelProvider.notifier).pickImage(ImageSource.camera);
            } : null,
            onGalleryTap: user?.role == 'technician' ? () {
              ref.read(chatbotViewModelProvider.notifier).pickImage(ImageSource.gallery);
            } : null,
            onRemoveImage: user?.role == 'technician' ? () {
              ref.read(chatbotViewModelProvider.notifier).removeSelectedImage();
            } : null,
          ),
        ],
      ),
    );
  }
}

