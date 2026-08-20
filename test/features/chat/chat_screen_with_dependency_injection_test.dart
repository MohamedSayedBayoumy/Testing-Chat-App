import 'package:chat_app/features/chat/chat_screen.dart';
import 'package:chat_app/features/chat/cubit/chat_cubit.dart';
import 'package:chat_app/features/chat/models/gemini_request_model.dart';
import 'package:chat_app/features/chat/models/gemini_response_model.dart';
import 'package:chat_app/features/chat/models/message_model.dart';
import 'package:chat_app/features/chat/repos/chat_repos.dart';
import 'package:chat_app/service/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class ChatRepositoryMock extends Mock implements ChatRepository {}

class GeminiRequestBodyFake extends Fake implements GeminiRequestBody {}

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
  late ChatRepositoryMock chatRepositoryMock;

  setUpAll(() {
    registerFallbackValue(GeminiRequestBodyFake());
  });

  setUp(() async {
    chatRepositoryMock = ChatRepositoryMock();

    await serviceLocator.reset();

    serviceLocator.registerSingleton<ChatCubit>(ChatCubit(chatRepositoryMock));
  });
  group("Test Chat Screen", () {
    testWidgets('Loading Case ...', (tester) async {
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
        MaterialApp(
          home: BlocProvider<ChatCubit>(
            create: (context) => serviceLocator<ChatCubit>()..startListening(),
            child: ChatScreen(),
          ),
        ),
      );

      await tester.pump();

      final textField = find.byKey(Key('text_field'));

      await tester.enterText(textField, "Hello");

      // this timer cause we have startListening() it listen to text filed every milliseconds: 100 
      await tester.pump(const Duration(milliseconds: 150));

      final sendIcon = find.byKey(Key('send_icon'));

      await tester.tap(sendIcon);

      await tester.pump();
      final loadingFiled = find.byType(CircleAvatar);

      expect(loadingFiled, findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 4));
    });
  });
}
