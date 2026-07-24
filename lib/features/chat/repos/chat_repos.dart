import 'dart:developer';

import 'package:chat_app/core/network/dio_services.dart';
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
  final DioServices dioServices;

  const ChatRepositoryImpl(this.dioServices);

  @override
  Future<Either<CommonFailedModel, GeminiResponse>> sendMessage(
    GeminiRequestBody messages,
  ) async {
    try {
      final response = await dioServices.dio.post(
        'gemini-flash-latest:generateContent',
        data: messages.toJson(),
      );

      // final response = await serviceLocator<Dio>().post(
      //   'gemini-flash-latest:generateContent',
      //   data: messages.toJson(),
      // );

      return Right(GeminiResponse.fromJson(response.data));
    } on DioException catch (e) {
      log("message: ${e.response?.data["error"]["message"]}");
      return Left(DioFailure.fromDioException(dioType: e.type, exception: e));
    }
  }
}
