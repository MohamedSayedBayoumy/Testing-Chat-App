import 'package:chat_app/core/error/common_failed_model.dart';
import 'package:chat_app/core/network/dio_services.dart';
import 'package:chat_app/core/services/chat_services.dart';
import 'package:chat_app/features/chat/models/gemini_request_model.dart';
import 'package:chat_app/features/chat/models/gemini_response_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class DioServicesTest extends Mock implements DioServices {}

class GeminiRequestBodyFake extends Fake implements GeminiRequestBody {}

Response _response() => Response(
  data: {
    "candidates": [
      {
        "content": {
          "parts": [
            {
              "text":
                  "AI works by analyzing massive amounts of **data**, finding **patterns**, and using those patterns to **predict answers** or make decisions. \n\nIn short: **Data + Pattern Recognition = Smart Output.**",
              "thoughtSignature":
                  "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",
            },
          ],
          "role": "model",
        },
        "finishReason": "STOP",
        "index": 0,
      },
    ],
    "usageMetadata": {
      "promptTokenCount": 9,
      "candidatesTokenCount": 41,
      "totalTokenCount": 548,
      "promptTokensDetails": [
        {"modality": "TEXT", "tokenCount": 9},
      ],
      "thoughtsTokenCount": 498,
      "serviceTier": "standard",
    },
    "modelVersion": "gemini-3.6-flash",
    "responseId": "z3NnatCdJZeF-8YP58DrsQU",
  },
  requestOptions: RequestOptions(),
);

DioException _retryableDioException() => DioException(
  type: DioExceptionType.sendTimeout,
  requestOptions: RequestOptions(),
);

DioException _nonRetryableDioException() => DioException(
  type: DioExceptionType.cancel,
  requestOptions: RequestOptions(),
);

void main() {
  late GeminiChatServices geminiChatServices;
  late DioServicesTest dioServicesTest;

  setUpAll(() {
    registerFallbackValue(GeminiRequestBodyFake());
  });

  setUp(() {
    dioServicesTest = DioServicesTest();
    geminiChatServices = GeminiChatServices(dioServicesTest);
  });

  group("Test Retry logic", () {
    test("Succeeded First From Time", () async {
      when(
        () => dioServicesTest.post(
          path: any(named: "path"),
          data: any(named: "data"),
        ),
      ).thenAnswer((_) async => _response());

      final requestBodyModel = GeminiRequestBody(contents: []);

      final result = await geminiChatServices.sendMessage(
        requestBody: requestBodyModel,
      );

      final callCount = verify(
        () => dioServicesTest.post(
          path: any(named: "path"),
          data: any(named: "data"),
        ),
      ).callCount;

      expect(callCount, 1);

      result.fold(
        (left) {
          fail("Expected Right (Success) but got Left (Error): $left");
        },
        (right) {
          expect(right, isA<GeminiResponse>());
        },
      );
    });

    test(
      "Failed First Time if exception is from Retryable Type will try again then Succeeded Second From Time",
      () async {
        int counter = 0;
        when(
          () => dioServicesTest.post(
            path: any(named: "path"),
            data: any(named: "data"),
          ),
        ).thenAnswer((_) async {
          counter++;
          if (counter == 1) {
            throw _retryableDioException();
          }

          return _response();
        });

        final requestBodyModel = GeminiRequestBody(contents: []);

        final result = await geminiChatServices.sendMessage(
          requestBody: requestBodyModel,
        );

        final callCount = verify(
          () => dioServicesTest.post(
            path: any(named: "path"),
            data: any(named: "data"),
          ),
        ).callCount;

        expect(callCount, 2);

        result.fold(
          (left) {
            fail("Expected Right (Success) but got Left (Error): $left");
          },
          (right) {
            expect(right, isA<GeminiResponse>());
          },
        );
      },
    );

    test("Failed First Time", () async {
      when(
        () => dioServicesTest.post(
          path: any(named: "path"),
          data: any(named: "data"),
        ),
      ).thenAnswer((_) async {
        throw _nonRetryableDioException();
      });

      final requestBodyModel = GeminiRequestBody(contents: []);

      final result = await geminiChatServices.sendMessage(
        requestBody: requestBodyModel,
      );

      final callCount = verify(
        () => dioServicesTest.post(
          path: any(named: "path"),
          data: any(named: "data"),
        ),
      ).callCount;

      expect(callCount, 1);

      result.fold((left) {
        expect(left, isA<CommonFailedModel>());
      }, (right) {});
    });

    test(
      "Failed First and Second Time if exception is from Retryable Type will try again then Succeeded Third From Time",
      () async {
        int counter = 0;
        when(
          () => dioServicesTest.post(
            path: any(named: "path"),
            data: any(named: "data"),
          ),
        ).thenAnswer((_) async {
          counter++;
          if (counter == 3) {
            return _response();
          }

          throw _retryableDioException();
        });

        final requestBodyModel = GeminiRequestBody(contents: []);

        final result = await geminiChatServices.sendMessage(
          requestBody: requestBodyModel,
        );

        final callCount = verify(
          () => dioServicesTest.post(
            path: any(named: "path"),
            data: any(named: "data"),
          ),
        ).callCount;

        expect(callCount, 3);

        result.fold(
          (left) {
            fail("Expected Right (Success) but got Left (Error): $left");
          },
          (right) {
            expect(right, isA<GeminiResponse>());
          },
        );
      },
    );
  });
}
