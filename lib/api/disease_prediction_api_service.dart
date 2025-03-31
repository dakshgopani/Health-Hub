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

  Future<Map<String, String>> generateDiseaseDetails(String disease) async {
    final sections = [
      'Cause',
      'Possible Symptoms',
      'When to Seek Medical Advice',
      'Potential Complications',
      'Recommendation',
      'Important Note'
    ];

    try {
      final response = await http.post(
        Uri.parse('$geminiUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                  'Generate clear, concise, and informative content about "$disease" for the following sections: Cause, Possible Symptoms, When to Seek Medical Advice, Potential Complications, and Recommendation. Also, include a note advising to consult a doctor.'
                }
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 500,
            'temperature': 0.7,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Ensure the expected data structure exists
        if (data.containsKey('candidates') &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0].containsKey('content') &&
            data['candidates'][0]['content'].containsKey('parts') &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          String generatedText =
          data['candidates'][0]['content']['parts'][0]['text'];

          // Debug print to see the raw response
          print("Generated Text: $generatedText");

          // Parse and clean the text
          Map<String, String> details =
          _parseGeneratedText(generatedText, sections);
          return details;
        } else {
          throw Exception('Invalid response format from API');
        }
      } else {
        throw Exception(
            'Failed to fetch disease details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching disease details: $e');
      return {
        'error': 'Unable to fetch disease details. Please try again later.'
      };
    }
  }

  Map<String, String> _parseGeneratedText(String text, List<String> sections) {
    Map<String, String> details = {};

    // Loop over each section to extract and clean the text
    for (var section in sections) {
      // Define a regular expression to match the section and its content
      RegExp regex = RegExp(
          '$section:(.*?)(?=${sections.where((s) => s != section).join('|')}|\\\$)',
          dotAll: true);

      // Get the matched text for the current section
      String? match = regex.firstMatch(text)?.group(1)?.trim();

      // If a match is found, clean it
      if (match != null) {
        // Clean up unwanted characters like '*', '•', and extra spaces
        match = match.replaceAll(RegExp(r'[*•]'), '').trim();
        details[section] = match.isNotEmpty ? match : 'No data available';
      } else if (section == 'Important Note') {
        details['Important Note'] =
        'This information is for general knowledge and does not constitute medical advice. It is essential to consult a doctor for diagnosis and treatment of any suspected illness. Do not self-treat.';
      } else {
        details[section] = 'No data available';
      }
    }

    return details;
  }
}