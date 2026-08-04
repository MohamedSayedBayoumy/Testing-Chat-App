import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioServices {
  Dio dio =
      Dio(
          BaseOptions(
            baseUrl: "https://generativelanguage.googleapis.com/v1beta/models/",
            connectTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.addAll([
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token =
                  "AQ.Ab8RN6IT0kfSRyPQoUy_WMgN8AHDJkLHbz9cyEdd14oeti4PTw";

              if (token.toString().isNotEmpty) {
                options.headers['X-goog-api-key'] = token;
              } else {
                options.headers.remove('Authorization');
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
