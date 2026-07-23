import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/chat_cubit.dart';
import 'widgets/app_bar_widget.dart';
import 'widgets/messages_list_widget.dart';
import 'widgets/text_input_widget.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomChatAppBar(),
      body: BlocConsumer<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state is WaitingForResponse) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Please wait, your message is being sent..."),
                backgroundColor: Colors.red.shade500,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Positioned.fill(child: MessagesListWidget()),

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
