import 'package:dartz/dartz.dart';

import '../../../core/error/common_failed_model.dart';
import '../../../core/network/dio_services.dart';
import '../models/gemini_response_model.dart';
import '../models/gemini_request_model.dart';

abstract class ChatRepository {
  Future<Either<CommonFailedModel, GeminiResponse>> sendMessage({
    required GeminiRequestBody requestBody,
  });
}

class ChatRepositoryImpl implements ChatRepository {
  final DioServices dioServices;

  const ChatRepositoryImpl(this.dioServices);

  @override
  Future<Either<CommonFailedModel, GeminiResponse>> sendMessage({
    required GeminiRequestBody requestBody,
  }) async {
    if (requestBody.contents!.length > 20) {
      requestBody = GeminiRequestBody(
        contents: requestBody.contents!.sublist(1, 5),
      );
    }

    return dioServices.sendMessage(requestBody: requestBody);
  }
}
