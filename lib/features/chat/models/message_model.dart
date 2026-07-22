class MessageModel {
  final List<PartModel>? parts;
  final String? role;

  MessageModel({required this.parts, required this.role});

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      parts: (json['parts'] as List<dynamic>?)
          ?.map((e) => PartModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'parts': parts?.map((e) => e.toJson()).toList(), 'role': role};
  }
}

class PartModel {
  String? text;
  final String? thoughtSignature;

  PartModel({required this.text, this.thoughtSignature});

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      text: json['text'] as String?,
      thoughtSignature: json['thoughtSignature'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (thoughtSignature != null) 'thoughtSignature': thoughtSignature,
    };
  }
}
