
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/chat_cubit.dart';

class TextInputWidget extends StatelessWidget {
  const TextInputWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    return Container(
      height: 56,
      padding: const EdgeInsetsDirectional.only(start: 20, end: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: cubit.messageController,
              decoration: const InputDecoration(
                hintText: 'Write your message',
                hintStyle: TextStyle(color: Color(0xFFA1A7B3), fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
          // const SizedBox(width: 10),
          // IconButton(
          //   icon: const Icon(
          //     Icons.mic_none,
          //     color: Color(0xFFA1A7B3),
          //     size: 28,
          //   ),
          //   onPressed: () {},
          // ),
          StreamBuilder(
            stream: cubit.sendMessageController.stream,
            builder: (context, snapshot) {
              return IconButton(
                icon: Icon(
                  Icons.send,
                  color: snapshot.data == true
                      ? Color(0xFF327CF2)
                      : Color(0xFFA1A7B3),
                  size: 28,
                ),
                onPressed: () {
                  if (snapshot.data == true) {
                    cubit.sendMessage();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
