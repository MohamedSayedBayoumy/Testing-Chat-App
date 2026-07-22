import 'message_model.dart';

class GeminiResponse {
  final List<CandidateModel>? candidates;

  GeminiResponse({this.candidates});

  factory GeminiResponse.fromJson(Map<String, dynamic> json) {
    return GeminiResponse(
      candidates: (json['candidates'] as List<dynamic>?)
          ?.map((e) => CandidateModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'candidates': candidates?.map((e) => e.toJson()).toList()};
  }
}

class CandidateModel {
  final MessageModel? content;

  CandidateModel({this.content});

  factory CandidateModel.fromJson(Map<String, dynamic> json) {
    return CandidateModel(
      content: json['content'] != null
          ? MessageModel.fromJson(json['content'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'content': content?.toJson()};
  }
}
