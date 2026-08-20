import 'package:chat_app/features/chat/chat_screen.dart';
import 'package:chat_app/features/chat/cubit/chat_cubit.dart';
import 'package:chat_app/features/chat/models/gemini_response_model.dart';
import 'package:chat_app/features/chat/models/message_model.dart';
import 'package:chat_app/features/chat/repos/chat_repos.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChatCubit extends MockCubit<ChatState> implements ChatCubit {}

class ChatRepositoryMock extends Mock implements ChatRepository {}

GeminiResponse _geminiResponse() => GeminiResponse(
  candidates: [
    CandidateModel(
      content: MessageModel(
        role: 'model',
        parts: [PartModel(text: 'Hello! How can I help you today?')],
      ),
    ),
  ],
);

void main() {
  late MockChatCubit mockCubit;

  late ChatRepositoryMock chatRepositoryMock;

  setUp(() {
    mockCubit = MockChatCubit();
    chatRepositoryMock = ChatRepositoryMock();
  });
  group("Chat Screen Test", () {
    testWidgets('Test Loading Case ...', (tester) async {
      when(
        () => chatRepositoryMock.sendMessage(
          requestBody: any(named: "requestBody"),
        ),
      ).thenAnswer((_) async {
        return Future.delayed(const Duration(seconds: 3), () {
          return Right(_geminiResponse());
        });
      });

      await tester.pumpWidget(
        BlocProvider<ChatCubit>.value(value: mockCubit, child: ChatScreen()),
      );

      await tester.pumpAndSettle();

      final textField = find.byKey(Key('text_field'));

      tester.enterText(textField, "Hello");

      final sendIcon = find.byKey(Key('send_icon'));

      await tester.tap(sendIcon);
    });
  });
}
