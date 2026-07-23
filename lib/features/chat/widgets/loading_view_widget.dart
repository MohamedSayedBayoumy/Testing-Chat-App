import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/chat_cubit.dart';

class LoadingViewWidget extends StatelessWidget {
  const LoadingViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChatCubit>().state;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: state is MessageSending || state is WaitingForResponse
          ? const CircleAvatar(
              key: ValueKey('loading_indicator'),
              backgroundColor: Colors.white,
              child: CircularProgressIndicator.adaptive(),
            )
          : const SizedBox.shrink(key: ValueKey('empty_space')),
    );
  }
}
