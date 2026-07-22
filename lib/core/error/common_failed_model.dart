import 'dart:developer';

import 'package:dio/dio.dart';

abstract class CommonFailedModel {
  String? failureMessage;
  String? failureMessageTitle;
  final DioException modelException;

  CommonFailedModel({
    required this.modelException,
    this.failureMessageTitle,
    required this.failureMessage,
  });
}

class DioFailure extends CommonFailedModel {
  DioFailure({
    super.failureMessage,
    super.failureMessageTitle,
    required super.modelException,
  });

  static String formatServerErrors(dynamic data) {
    if (data is List) {
      final items = data.whereType<String>().toList();
      if (items.isNotEmpty) return items.map((e) => '• $e').join('\n');
    }
    if (data is Map) {
      final List<String> lines = [];
      data.forEach((key, value) {
        if (value is List) {
          for (final v in value) {
            if (v is String) lines.add('• $v');
          }
        } else if (value is String) {
          lines.add('• $value');
        }
      });
      if (lines.isNotEmpty) return lines.join('\n');
    }
    return data?.toString() ?? '';
  }

  factory DioFailure.fromDioException({
    DioExceptionType? dioType,
    DioException? exception,
  }) {
    switch (dioType!) {
      case DioExceptionType.connectionTimeout:
        log("DioExceptionType.connectionTimeout");
        return DioFailure(
          failureMessage: 'errors.connection_error',
          modelException: exception!,
        );
      case DioExceptionType.sendTimeout:
        log("DioExceptionType.sendTimeout");
        return DioFailure(
          failureMessage: 'errors.timeout_30s',
          modelException: exception!,
        );
      case DioExceptionType.receiveTimeout:
        log("DioExceptionType.receiveTimeout");
        return DioFailure(
          failureMessage: 'errors.timeout_30s',
          modelException: exception!,
        );
      case DioExceptionType.badCertificate:
        log("DioExceptionType.badCertificate");
        return DioFailure(
          failureMessage: 'errors.bad_certificate',
          modelException: exception!,
        );
      case DioExceptionType.badResponse:
        log("DioExceptionType.badResponse");

        return DioFailure(
          failureMessageTitle: "serverMessageTitle",
          failureMessage: 'errors.bad_response',
          modelException: exception!,
        );
      case DioExceptionType.cancel:
        log("DioExceptionType.cancel");
        return DioFailure(
          failureMessage: 'errors.request_canceled',
          modelException: exception!,
        );

      case DioExceptionType.connectionError:
        return DioFailure(
          failureMessage: 'errors.connection_error',
          modelException: exception!,
        );

      case DioExceptionType.unknown:
        log("DioExceptionType.unknown");
        return DioFailure(
          failureMessage: 'errors.unknown',
          modelException: exception!,
        );
      case DioExceptionType.transformTimeout:
        throw UnimplementedError();
    }
  }
}
