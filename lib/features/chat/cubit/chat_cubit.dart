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

  Timer? _debounce;

  void startListening() {
    messageController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce?.cancel();

      _debounce = Timer(const Duration(milliseconds: 100), () {
        if (messageController.text.isEmpty) {
          sendMessageController.add(false);
        } else {
          sendMessageController.add(true);
        }
      });
    });
  }

  void sendMessage() async {
    if (state is MessageSending) {
      emit(WaitingForResponse());
      return;
    }

    messages.add(
      MessageModel(
        parts: [PartModel(text: messageController.text)],
        role: "user",
      ),
    );


    requestBody = GeminiRequestBody(contents: messages);

    String userMessage = messageController.text;

    messageController.clear();

    emit(MessageSending());
    final result = await chatRepository.sendMessage(requestBody: requestBody!);
    result.fold(
      (failure) {
        messages.removeLast();
        messageController.text = userMessage;

        emit(MessageFailed(failure.failureMessage!));
      },
      (response) {
        final responseMessage = response.candidates!.first.content!;

        messages.add(responseMessage);

        emit(MessageSended());
      },
    );
  }

  void getLastMessages() {
    var lastMessages = messages.sublist(
      messages.length > 3 ? messages.length - 3 : 0,
      messages.length,
    );
    requestBody = GeminiRequestBody(contents: lastMessages);
  }

  void dispose() {
    _debounce?.cancel();
    messageController.dispose();
    sendMessageController.close();
  }
}
