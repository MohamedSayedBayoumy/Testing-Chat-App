import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/chat_cubit.dart';
import 'chat_bubble.dart';

class MessagesListWidget extends StatelessWidget {
  const MessagesListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ChatCubit>();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      itemCount: cubit.messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(message: cubit.messages[index]);
      },
    );
  }
}
