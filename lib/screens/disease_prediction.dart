import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // For bar chart
import '../api/disease_prediction_api_service.dart';
import '../models/category_response.dart';
import '../models/symptom_response.dart';
import '../models/prediction_input.dart';
import '../models/prediction_response.dart';
// import '../api_service.dart';

class DiseasePredictionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiService()),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Disease Prediction',
        theme: ThemeData(
          primaryColor: const Color(0xFF6b7280),
          scaffoldBackgroundColor: const Color(0xFFf5f3ff),
          cardColor: Colors.white,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8b5cf6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Color(0xFF1f2937)),
            titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1f2937)),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: CategoryScreen(),
      ),
    );
  }
}

class CategoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ApiService apiService = Provider.of<ApiService>(context);

    return Scaffold(

      appBar: AppBar(
        title: const Text('Select Category', style: TextStyle(fontSize: 24)),
        backgroundColor: const Color(0xFF8b5cf6),
        elevation: 0,
      ),
      body: FutureBuilder<CategoryResponse>(
        future: apiService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF8b5cf6)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          } else {
            List<String> categories = snapshot.data!.categories;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 300 + index * 100),
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(categories[index], style: const TextStyle(fontSize: 18)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF8b5cf6)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SymptomScreen(category: categories[index]),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class SymptomScreen extends StatefulWidget {
  final String category;

  SymptomScreen({required this.category});

  @override
  _SymptomScreenState createState() => _SymptomScreenState();
}

class _SymptomScreenState extends State<SymptomScreen> with SingleTickerProviderStateMixin {
  Map<String, bool> currentSymptoms = {};
  int currentSymptomIndex = 0;
  List<String> symptoms = [];
  int remainingQuestions = 20;
  bool shouldStop = false;
  String? reasonToStop;
  PredictionResponse? predictionResponse;
  Map<String, Map<String, String>> symptomDetails = {};
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMeaningDialog(String symptom, String? meaning) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Meaning of $symptom',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  meaning ?? 'No meaning available.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ApiService apiService = Provider.of<ApiService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer Symptoms', style: TextStyle(fontSize: 24)),
        backgroundColor: const Color(0xFF8b5cf6),
        elevation: 0,
      ),
      body: FutureBuilder<SymptomResponse>(
        future: apiService.getInitialSymptoms(widget.category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF8b5cf6)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.symptoms.isEmpty) {
            return const Center(child: Text('No symptoms found.'));
          } else {
            if (symptoms.isEmpty) {
              symptoms = snapshot.data!.symptoms;
            }
            if (currentSymptomIndex >= symptoms.length) {
              shouldStop = true;
              reasonToStop = "no_more_symptoms";
            }

            if (shouldStop) {
              List<SymptomAnswer> answers = currentSymptoms.entries
                  .map((e) => SymptomAnswer(symptom: e.key, answer: e.value))
                  .toList();
              PredictionInput input = PredictionInput(
                  category: widget.category, currentSymptoms: answers);

              return FutureBuilder<PredictionResponse>(
                future: apiService.predictDisease(input),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF8b5cf6)));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text('No prediction result.'));
                  } else {
                    PredictionResponse response = snapshot.data!;
                    return PredictionResult(response: response);
                  }
                },
              );
            }

            String currentSymptom = capitalize(symptoms[currentSymptomIndex]);
            return FadeTransition(
              opacity: _fadeAnimation,
              child: FutureBuilder<Map<String, String>>(
                future: apiService.fetchSymptomDetails(currentSymptom),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF8b5cf6)));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return Center(child: Text('No details found for $currentSymptom.'));
                  } else {
                    symptomDetails[currentSymptom] = snapshot.data!;
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _showMeaningDialog(
                                  currentSymptom,
                                  symptomDetails[currentSymptom]!['meaning'],
                                );
                              },
                              child: Text(
                                'Do you have $currentSymptom?',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    await handleSymptomResponse(apiService, true);
                                    _controller.reset();
                                    _controller.forward();
                                  },
                                  child: const Text('Yes', style: TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    await handleSymptomResponse(apiService, false);
                                    _controller.reset();
                                    _controller.forward();
                                  },
                                  child: const Text('No', style: TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            if (predictionResponse != null)
                              PredictionResult(response: predictionResponse!),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> handleSymptomResponse(ApiService apiService, bool answer) async {
    setState(() {
      currentSymptoms[symptoms[currentSymptomIndex]] = answer;
      currentSymptomIndex++;
      remainingQuestions--;
    });

    List<SymptomAnswer> answers = currentSymptoms.entries
        .map((e) => SymptomAnswer(symptom: e.key, answer: e.value))
        .toList();
    PredictionInput input =
    PredictionInput(category: widget.category, currentSymptoms: answers);

    PredictionResponse response = await apiService.predictDisease(input);
    setState(() {
      predictionResponse = response;
      if (response.confidence >= 0.90 ||
          remainingQuestions <= 0 ||
          response.nextSymptom == null) {
        shouldStop = true;
        reasonToStop = response.reasonToStop;
      } else {
        symptoms.insert(currentSymptomIndex, response.nextSymptom!);
      }
    });
  }

  String capitalize(String symptom) {
    return symptom
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class PredictionResult extends StatelessWidget {
  final PredictionResponse response;

  PredictionResult({required this.response});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Predicted Disease: ${response.predictedDisease}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${(response.confidence * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF8b5cf6)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Top Predictions:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...response.topPredictions.map((prediction) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '${capitalize(prediction.keys.first)}: ${(prediction.values.first * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(fontSize: 14),
                    ),
                  )),
                  const SizedBox(height: 16),
                  Text('Questions Remaining: ${response.questionsRemaining}'),
                  if (response.shouldStop)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Reason to Stop: ${response.reasonToStop}',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Prediction Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 300, // Increased height for better visibility
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100, // Set max Y to 100 for percentage clarity
                  barGroups: response.topPredictions.asMap().entries.map((entry) {
                    int index = entry.key;
                    var prediction = entry.value;
                    String disease = prediction.keys.first;
                    double confidence = prediction.values.first * 100;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: confidence,
                          color: const Color(0xFF8b5cf6).withOpacity(0.8 + (index * 0.1)), // Gradient effect
                          width: 20, // Wider bars
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60, // Increased for rotated text
                        getTitlesWidget: (value, meta) {
                          String title = response.topPredictions[value.toInt()].keys.first;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Transform.rotate(
                              angle: -45 * 3.14159 / 180, // Rotate 45 degrees
                              child: Text(
                                capitalize(title),
                                style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8), // Function returning color
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${(rod.toY).toStringAsFixed(1)}%',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String capitalize(String symptom) {
    return symptom
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}