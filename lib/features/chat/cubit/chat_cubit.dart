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

  // List<MessageModel> messages = [];

  List<MessageModel> messages = [
    MessageModel(
      role: 'user',
      parts: [
        PartModel(
          text:
              'What are the best practices for high-level system design in mobile applications?',
        ),
      ],
    ),
    MessageModel(
      role: 'model',
      parts: [
        PartModel(
          text:
              'A solid application architecture focuses on separation of concerns. You should deeply decouple your UI layer from the business logic and data layers to ensure scalability, testability, and easier maintenance across the entire system.',
          thoughtSignature: 'Analyzing system design principles',
        ),
      ],
    ),
    MessageModel(
      role: 'user',
      parts: [
        PartModel(
          text:
              'That makes perfect sense. On a different note, I am currently studying backend development. What is the name of the C# compiler?',
        ),
      ],
    ),
    MessageModel(
      role: 'model',
      parts: [
        PartModel(
          text:
              'The modern C# compiler is called "Roslyn". It is open-source and provides rich code analysis APIs that let you read, write, and analyze C# and Visual Basic code.',
        ),
      ],
    ),
    MessageModel(
      role: 'user',
      parts: [
        PartModel(
          text:
              'That makes perfect sense. On a different note, I am currently studying backend development. What is the name of the C# compiler?',
        ),
      ],
    ),
    MessageModel(
      role: 'model',
      parts: [
        PartModel(
          text:
              'The modern C# compiler is called "Roslyn". It is open-source and provides rich code analysis APIs that let you read, write, and analyze C# and Visual Basic code.',
        ),
      ],
    ),
    MessageModel(
      role: 'user',
      parts: [
        PartModel(
          text:
              'That makes perfect sense. On a different note, I am currently studying backend development. What is the name of the C# compiler?',
        ),
      ],
    ),
    MessageModel(
      role: 'model',
      parts: [
        PartModel(
          text:
              'The modern C# compiler is called "Roslyn". It is open-source and provides rich code analysis APIs that let you read, write, and analyze C# and Visual Basic code.',
        ),
      ],
    ),
    MessageModel(
      role: 'user',
      parts: [
        PartModel(
          text:
              'That makes perfect sense. On a different note, I am currently studying backend development. What is the name of the C# compiler?',
        ),
      ],
    ),
    MessageModel(
      role: 'model',
      parts: [
        PartModel(
          text:
              'The modern C# compiler is called "Roslyn". It is open-source and provides rich code analysis APIs that let you read, write, and analyze C# and Visual Basic code.',
        ),
      ],
    ),
    MessageModel(
      role: 'user',
      parts: [
        PartModel(
          text:
              'That makes perfect sense. On a different note, I am currently studying backend development. What is the name of the C# compiler?',
        ),
      ],
    ),
    MessageModel(
      role: 'model',
      parts: [
        PartModel(
          text:
              'The modern C# compiler is called "Roslyn". It is open-source and provides rich code analysis APIs that let you read, write, and analyze C# and Visual Basic code.',
        ),
      ],
    ),
    MessageModel(
      role: 'user',
      parts: [
        PartModel(
          text:
              'That makes perfect sense. On a different note, I am currently studying backend development. What is the name of the C# compiler?',
        ),
      ],
    ),
    MessageModel(
      role: 'model',
      parts: [
        PartModel(
          text:
              'The modern C# compiler is called "Roslyn". It is open-source and provides rich code analysis APIs that let you read, write, and analyze C# and Visual Basic code.',
        ),
      ],
    ),
    MessageModel(
      role: 'user',
      parts: [
        PartModel(
          text:
              'That makes perfect sense. On a different note, I am currently studying backend development. What is the name of the C# compiler?',
        ),
      ],
    ),
    MessageModel(
      role: 'model',
      parts: [
        PartModel(
          text:
              'The modern C# compiler is called "Roslyn". It is open-source and provides rich code analysis APIs that let you read, write, and analyze C# and Visual Basic code.',
        ),
      ],
    ),
    MessageModel(
      role: 'user',
      parts: [
        PartModel(
          text:
              'That makes perfect sense. On a different note, I am currently studying backend development. What is the name of the C# compiler?',
        ),
      ],
    ),
    MessageModel(
      role: 'model',
      parts: [
        PartModel(
          text:
              'The modern C# compiler is called "Roslyn". It is open-source and provides rich code analysis APIs that let you read, write, and analyze C# and Visual Basic code.',
        ),
      ],
    ),
    MessageModel(
      role: 'user',
      parts: [
        PartModel(
          text:
              'That makes perfect sense. On a different note, I am currently studying backend development. What is the name of the C# compiler?',
        ),
      ],
    ),
    MessageModel(
      role: 'model',
      parts: [
        PartModel(
          text:
              'The modern C# compiler is called "Roslyn". It is open-source and provides rich code analysis APIs that let you read, write, and analyze C# and Visual Basic code.',
        ),
      ],
    ),
  ];

  GeminiRequestBody? requestBody;

  TextEditingController messageController = TextEditingController(text: "");

  StreamController<bool> sendMessageController =
      StreamController<bool>.broadcast();

  MessageModel currentMessage = MessageModel(
    parts: [PartModel(text: '')],
    role: 'user',
  );

  Timer? _debounce;

  void startListening() {
    messageController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce?.cancel();

      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (messageController.text.isEmpty) {
          sendMessageController.add(false);
        } else {
          sendMessageController.add(true);
        }
        currentMessage.parts![0].text = messageController.text;
      });
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

  void dispose() {
    _debounce?.cancel();
    messageController.dispose();
    sendMessageController.close();
  }
}
