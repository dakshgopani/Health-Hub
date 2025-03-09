class SymptomAnswer {
  final String symptom;
  final bool answer;

  SymptomAnswer({required this.symptom, required this.answer});

  factory SymptomAnswer.fromJson(Map<String, dynamic> json) {
    return SymptomAnswer(
      symptom: json['symptom'],
      answer: json['answer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symptom': symptom,
      'answer': answer,
    };
  }
}

class PredictionInput {
  final String category;
  final List<SymptomAnswer> currentSymptoms;

  PredictionInput({required this.category, required this.currentSymptoms});

  factory PredictionInput.fromJson(Map<String, dynamic> json) {
    return PredictionInput(
      category: json['category'],
      currentSymptoms: (json['current_symptoms'] as List)
          .map((i) => SymptomAnswer.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'current_symptoms': currentSymptoms.map((e) => e.toJson()).toList(),
    };
  }
}
