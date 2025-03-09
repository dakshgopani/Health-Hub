class SymptomResponse {
  final List<String> symptoms;
  final int remainingQuestions;

  SymptomResponse({required this.symptoms, required this.remainingQuestions});

  factory SymptomResponse.fromJson(Map<String, dynamic> json) {
    return SymptomResponse(
      symptoms: List<String>.from(json['symptoms']),
      remainingQuestions: json['remaining_questions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symptoms': symptoms,
      'remaining_questions': remainingQuestions,
    };
  }
}
