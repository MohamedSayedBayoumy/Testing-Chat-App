import 'package:chat_app/core/services/chat_services.dart';
import 'package:dartz/dartz.dart';

import '../../../core/error/common_failed_model.dart';
import '../models/gemini_response_model.dart';
import '../models/gemini_request_model.dart';

abstract class ChatRepository {
  Future<Either<CommonFailedModel, GeminiResponse>> sendMessage({
    required GeminiRequestBody requestBody,
  });
}

class ChatRepositoryImpl implements ChatRepository {
  final GeminiChatServices geminiChatServices;

  const ChatRepositoryImpl(this.geminiChatServices);

  @override
  Future<Either<CommonFailedModel, GeminiResponse>> sendMessage({
    required GeminiRequestBody requestBody,
  }) async {
    if (requestBody.contents!.length > 20) {
      requestBody = GeminiRequestBody(
        contents: requestBody.contents!.sublist(1, 5),
      );
    }

    return geminiChatServices.sendMessage(requestBody: requestBody);
  }
}
