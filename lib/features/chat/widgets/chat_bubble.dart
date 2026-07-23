import 'package:flutter/material.dart';

import '../models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? const Color(0xFF327CF2) : const Color(0xFFF3F3F3);
    final textColor = isUser ? Colors.white : const Color(0xFF1F2937);

    final radius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(0),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) // عرض أيقونة البوت بجانب رسائل البوت فقط
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 10.0),
                  child: Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: Colors.transparent, // اللون الخلفي شفاف هنا
                    ),
                    child: Image.asset(
                      'assets/bot_bubble.png', // هنا هتحط صورة أيقونة البوت للفقاعات
                      height: 20,
                      width: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.roundabout_left_rounded,
                          size: 20,
                          color: Color(0xFF327CF2),
                        );
                      },
                    ),
                  ),
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(color: color, borderRadius: radius),
                child: Text(
                  message.parts!.first.text!,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    height: 1.4, // تباعد سطري خفيف
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14), // مسافة بين الفقاعات
        ],
      ),
    );
  }
}
