import 'package:chat_app/features/chat/cubit/chat_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/app_bar_widget.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/text_input_widget.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomChatAppBar(),
      body: BlocConsumer<ChatCubit, ChatState>(
        listener: (context, state) {},
        builder: (context, state) {
          final cubit = context.watch<ChatCubit>();
          return Stack(
            children: [
              Positioned.fill(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  itemCount: cubit.messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(message: cubit.messages[index]);
                  },
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 50,
                child: TextInputWidget(),
              ),
            ],
          );
        },
      ),
    );
  }
}
