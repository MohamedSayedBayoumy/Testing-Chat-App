import 'package:chat_app/core/network/dio_services.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../features/chat/models/gemini_request_model.dart';
import '../../features/chat/models/gemini_response_model.dart';
import '../error/common_failed_model.dart';

class GeminiChatServices {
  final DioServices dioServices;

  GeminiChatServices(this.dioServices);

  Future<Either<CommonFailedModel, GeminiResponse>> sendMessage({
    required GeminiRequestBody requestBody,
  }) async {
    Exception? exception;
    for (int i = 0; i < 3; i++) {
      try {
        final response = await dioServices.post(
          path: 'gemini-flash-latest:generateContent',
          data: requestBody.toJson(),
        );

        return Right(GeminiResponse.fromJson(response.data));
      } on DioException catch (e) {
        // this mean => if not of any from _isRetryableDioException Close Fun Direct
        if (!_isRetryableDioException(e)) {
          // rethrow;
          //rethrow: بتقول للدالة "اقفلي واخرجي بطوارئ وارمي الإيرور ده في وش اللي نادانا".
          // rethrow :mean Stop any thing and go out
          // we will stop this function if Dio Exception in not type of _isRetryableDioException

          return Left(
            DioFailure.fromDioException(dioType: e.type, exception: e),
          );
        }
        exception = e;
        if (i < 2) {
          await Future.delayed(Duration(seconds: i + 1));
        }
      }
    }
    throw exception!;
  }

  bool _isRetryableDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == null) return false;
        return code == 408 || code == 429 || (code >= 500 && code < 600);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return false;
      case DioExceptionType.unknown:
        return false;
    }
  }
}
