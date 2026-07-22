
import 'message_model.dart';

class GeminiRequestBody {
  final List<MessageModel>? contents;

  GeminiRequestBody({this.contents});

  factory GeminiRequestBody.fromJson(Map<String, dynamic> json) {
    return GeminiRequestBody(
      contents: (json['contents'] as List<dynamic>?)
          ?.map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contents': contents?.map((e) => e.toJson()).toList(),
    };
  }
}