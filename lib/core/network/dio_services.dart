import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../flavor/app_config.dart';

class DioServices {
  Dio dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.currentBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      )
      ..interceptors.addAll([
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = AppConfig.currentApiKey;

            if (token.isNotEmpty) {
              options.headers['X-goog-api-key'] = token;
            } else {
              options.headers.remove('X-goog-api-key');
            }
            return handler.next(options);
          },
        ),
        if (kDebugMode) ...[
          PrettyDioLogger(
            requestHeader: true,
            requestBody: true,
            responseBody: true,
            responseHeader: false,
            error: true,
            compact: true,
            maxWidth: 100,
          ),
        ],
      ]);

  Future<Response> post({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return await dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
}
