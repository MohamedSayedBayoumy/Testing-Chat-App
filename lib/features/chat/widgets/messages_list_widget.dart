
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/chat_cubit.dart';
import 'chat_bubble.dart';

class MessagesListWidget extends StatelessWidget {
  const MessagesListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ChatCubit>();

    final isLoading =
        cubit.state is MessageSending || cubit.state is WaitingForResponse;

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      itemCount: isLoading ? cubit.messages.length + 1 : cubit.messages.length,
      itemBuilder: (context, index) {
        if (isLoading && index == 0) {
          return const CircleAvatar(
            backgroundColor: Colors.blue,
            child: CircularProgressIndicator.adaptive(
              backgroundColor: Colors.white,
            ),
          );
        }

        final messageIndex = isLoading ? index - 1 : index;

        final reversedIndex = cubit.messages.length - 1 - messageIndex;

        return ChatBubble(message: cubit.messages[reversedIndex]);
      },
    );
  }
}
