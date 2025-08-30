import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SessionChatWidget extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final Function(String) onSendMessage;
  final VoidCallback onClose;

  const SessionChatWidget({
    super.key,
    required this.messages,
    required this.onSendMessage,
    required this.onClose,
  });

  @override
  State<SessionChatWidget> createState() => _SessionChatWidgetState();
}

class _SessionChatWidgetState extends State<SessionChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(SessionChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
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

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35.w,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(230),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4.w),
          bottomLeft: Radius.circular(4.w),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withAlpha(51),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Live Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 5.w,
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(3.w),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final message = widget.messages[index];
                return _buildMessageItem(message);
              },
            ),
          ),

          // Message input
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withAlpha(51),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(6.w),
                      border: Border.all(
                        color: Colors.white.withAlpha(77),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: Colors.white.withAlpha(128),
                          fontSize: 12.sp,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 3.w),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 4.w,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final userProfile = message['user_profiles'];
    final isSystemMessage = message['message_type'] == 'system';
    final createdAt = DateTime.tryParse(message['created_at'] ?? '');

    if (isSystemMessage) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 1.w),
        child: Text(
          message['message'] ?? '',
          style: TextStyle(
            color: Colors.white.withAlpha(153),
            fontSize: 10.sp,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(77),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: userProfile?['avatar_url'] ??
                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile?['full_name'] ?? 'Unknown User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (createdAt != null)
                      Text(
                        _formatMessageTime(createdAt),
                        style: TextStyle(
                          color: Colors.white.withAlpha(128),
                          fontSize: 9.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 1.w),

          // Message content
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Text(
              message['message'] ?? '',
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 12.sp,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inHours}h';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}