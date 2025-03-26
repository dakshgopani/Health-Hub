import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/category_response.dart';
import '../models/symptom_response.dart';
import '../models/prediction_input.dart';
import '../models/prediction_response.dart';

class ApiService with ChangeNotifier {
  final String baseUrl = 'https://disease-prediction-jzs3.onrender.com';
  static const String apiKey =
      "AIzaSyBCvLTBFuntdAk-PoMRAVJGnIrinI0ZA2k"; // Replace with your actual API key
  static const String geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

  Future<CategoryResponse> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    if (response.statusCode == 200) {
      return CategoryResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<SymptomResponse> getInitialSymptoms(String category) async {
    final response = await http.get(Uri.parse('$baseUrl/symptoms/$category'));
    if (response.statusCode == 200) {
      return SymptomResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load symptoms');
    }
  }

  Future<PredictionResponse> predictDisease(PredictionInput input) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(input.toJson()),
    );
    if (response.statusCode == 200) {
      return PredictionResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to predict disease');
    }
  }

  Future<Map<String, String>> fetchSymptomDetails(String symptom) async {
    try {
      final response = await http.post(
        Uri.parse('$geminiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Explain the medical condition of $symptom in simple terms for a general audience in 1 line."
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String meaning = data['candidates'][0]['content']['parts'][0]['text'];

        return {"meaning": meaning};
      } else {
        return {"meaning": "No description available"};
      }
    } catch (e) {
      return {"meaning": "Error fetching data"};
    }
  }
}
