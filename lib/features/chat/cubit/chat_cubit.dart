import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/gemini_request_model.dart';
import '../models/message_model.dart';
import '../repos/chat_repos.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this.chatRepository) : super(ChatInitial());

  final ChatRepository chatRepository;

  List<MessageModel> messages = [];

  GeminiRequestBody? requestBody;

  TextEditingController messageController = TextEditingController(text: "");

  StreamController<bool> sendMessageController =
      StreamController<bool>.broadcast();

  MessageModel currentMessage = MessageModel(
    parts: [PartModel(text: '')],
    role: 'user',
  );

  void startListening() {
    messageController.addListener(() {
      if (messageController.text.isEmpty) {
        sendMessageController.add(false);
      } else {
        sendMessageController.add(true);
      }
      currentMessage.parts![0].text = messageController.text;
    });
  }

  void sendMessage() async {
    requestBody!.contents?.add(currentMessage);

    emit(MessageSending());
    final result = await chatRepository.sendMessage(requestBody!);
    result.fold(
      (failure) {
        emit(MessageFailed());
      },
      (response) {
        if (response.candidates!.length > 2) {
          requestBody!.contents?.removeAt(0);
        }
        requestBody!.contents?.add(response.candidates!.first.content!);

        emit(MessageSended());
      },
    );
  }
}
