import 'package:chat_app/core/network/dio_services.dart';
import 'package:chat_app/features/chat/models/gemini_request_model.dart';
import 'package:chat_app/features/chat/models/gemini_response_model.dart';
import 'package:chat_app/features/chat/models/message_model.dart';
import 'package:chat_app/features/chat/repos/chat_repos.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class DioServicesMock extends Mock implements DioServices {}

class GeminiRequestBodyFake extends Fake implements GeminiRequestBody {}

GeminiResponse _responseModel() {
  return GeminiResponse(
    candidates: List.generate(
      20,
      (index) => CandidateModel(
        content: MessageModel(
          role: 'user',
          parts: [
            PartModel(
              text:
                  'What are the best practices for high-level system design in mobile applications?',
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  late ChatRepositoryImpl chatRepositoryImpl;
  late DioServicesMock dioServicesMock;
  
  setUp(() {
    dioServicesMock = DioServicesMock();
    chatRepositoryImpl = ChatRepositoryImpl(dioServicesMock);
  });

  setUpAll(() {
    registerFallbackValue(GeminiRequestBodyFake());
  });

  group("Test logic of send messages", () {
    test(
      "Test When messages length doesn't change if length have less than or equal 20",
      () async {
        when(
          () => dioServicesMock.sendMessage(
            requestBody: any(named: "requestBody"),
          ),
        ).thenAnswer((_) async => Right(_responseModel()));

        GeminiRequestBody requestBodyTest = GeminiRequestBody(
          contents: List.generate(
            10,
            (index) => MessageModel(
              role: 'user',
              parts: [
                PartModel(
                  text:
                      'What are the best practices for high-level system design in mobile applications?',
                ),
              ],
            ),
          ),
        );

        await chatRepositoryImpl.sendMessage(requestBody: requestBodyTest);

        final actualMessagesLength =
            verify(
                  () => dioServicesMock.sendMessage(
                    requestBody: captureAny(named: "requestBody"),
                  ),
                ).captured.first
                as GeminiRequestBody;

        expect(
          actualMessagesLength.contents!.length, // 20
          requestBodyTest.contents!.length, // 20
        );
      },
    );
  });
}
