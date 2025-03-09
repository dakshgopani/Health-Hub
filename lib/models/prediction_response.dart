class PredictionResponse {
  final String predictedDisease;
  final double confidence;
  final List<Map<String, double>> topPredictions;
  final String? nextSymptom;
  final int questionsRemaining;
  final bool shouldStop;
  final String? reasonToStop;

  PredictionResponse({
    required this.predictedDisease,
    required this.confidence,
    required this.topPredictions,
    this.nextSymptom,
    required this.questionsRemaining,
    required this.shouldStop,
    this.reasonToStop,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      predictedDisease: json['predicted_disease'],
      confidence: json['confidence'],
      topPredictions: (json['top_predictions'] as List)
          .map((e) => Map<String, double>.from(e))
          .toList(),
      nextSymptom: json['next_symptom'],
      questionsRemaining: json['questions_remaining'],
      shouldStop: json['should_stop'],
      reasonToStop: json['reason_to_stop'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predicted_disease': predictedDisease,
      'confidence': confidence,
      'top_predictions': topPredictions,
      'next_symptom': nextSymptom,
      'questions_remaining': questionsRemaining,
      'should_stop': shouldStop,
      'reason_to_stop': reasonToStop,
    };
  }
}
