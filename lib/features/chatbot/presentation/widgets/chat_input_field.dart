import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSend;
  final bool isLoading;
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;
  final File? selectedImage;
  final VoidCallback? onRemoveImage;

  const ChatInputField({
    super.key,
    required this.onSend,
    this.isLoading = false,
    this.onCameraTap,
    this.onGalleryTap,
    this.selectedImage,
    this.onRemoveImage,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if ((text.isNotEmpty || widget.selectedImage != null) && !widget.isLoading) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image Preview
          if (widget.selectedImage != null)
            Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  height: 100.h,
                  width: 100.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    image: DecorationImage(
                      image: FileImage(widget.selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                    onPressed: widget.onRemoveImage,
                  ),
                ),
              ],
            ),
          // Input Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.onCameraTap != null)
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
                  onPressed: widget.onCameraTap,
                ),
              if (widget.onGalleryTap != null)
                IconButton(
                  icon: Icon(Icons.image, color: Theme.of(context).primaryColor),
                  onPressed: widget.onGalleryTap,
                ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !widget.isLoading,
                  style: GoogleFonts.rubik(fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    hintStyle: GoogleFonts.rubik(fontSize: 14.sp, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F291F) : Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                margin: EdgeInsets.only(bottom: 4.h),
                decoration: BoxDecoration(
                  color: widget.isLoading
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: widget.isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.send, color: Colors.white, size: 20.sp),
                  onPressed: widget.isLoading ? null : _handleSend,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

