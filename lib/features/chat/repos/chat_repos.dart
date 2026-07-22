import 'package:chat_app/service/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/error/common_failed_model.dart';
import '../models/gemini_response_model.dart';
import '../models/gemini_request_model.dart';

abstract class ChatRepository {
  Future<Either<CommonFailedModel, GeminiResponse>> sendMessage(
    GeminiRequestBody messages,
  );
}

class ChatRepositoryImpl implements ChatRepository {
  @override
  Future<Either<CommonFailedModel, GeminiResponse>> sendMessage(
    GeminiRequestBody messages,
  ) async {
    try {
      final response = await serviceLocator<Dio>().post(
        'gemini-flash-latest:generateContent',
        data: messages.toJson(),
      );

      return Right(GeminiResponse.fromJson(response.data));
    } on DioException catch (e) {
      return Left(DioFailure.fromDioException(dioType: e.type, exception: e));
    }
  }
}
