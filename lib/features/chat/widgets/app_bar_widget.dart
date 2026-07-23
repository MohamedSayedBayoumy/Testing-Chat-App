import 'package:flutter/material.dart';

class CustomChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomChatAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0xFFEFEFEF),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3), // شادو خفيف تحت الـ AppBar
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: Row(
          children: [
            Icon(Icons.rocket, color: Color(0xFF327CF2), size: 40),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ChatGPT',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CAF50), // اللون الأخضر للأونلاين
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // هنا بنحدد الارتفاع المطلوب للـ AppBar
  @override
  Size get preferredSize => const Size.fromHeight(70.0);
}
