import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_message_entity.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Avatar for bot messages
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: 18.sp,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isUser 
                    ? (isDark ? Theme.of(context).primaryColor : Theme.of(context).primaryColor)
                    : (isDark ? const Color(0xFF1F291F) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                  bottomLeft: Radius.circular(isUser ? 20.r : 4.r),
                  bottomRight: Radius.circular(isUser ? 4.r : 20.r),
                ),
                border: !isUser && !isDark 
                    ? Border.all(color: Colors.grey.shade200) 
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: Offset(0, 1.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.base64Image != null && message.base64Image!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.memory(
                          base64Decode(message.base64Image!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                    style: TextStyle(
                      color: isUser 
                          ? Colors.white 
                          : (isDark ? Colors.white : Colors.black87),
                      fontSize: 15.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isUser 
                              ? Colors.white70 
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          fontSize: 11.sp,
                        ),
                      ),
                      if (isUser) ...[
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.done_all,
                          size: 14.sp,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8.w),
            // Avatar for user messages
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 18.sp,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

