import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // For bar chart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../api/disease_prediction_api_service.dart';
import '../models/category_response.dart';
import '../models/symptom_response.dart';
import '../models/prediction_input.dart';
import '../models/prediction_response.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Color(0xFF1f2937)),
            titleLarge: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1f2937)),
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

    // Disease-to-icon mapping
    final Map<String, IconData> diseaseIcons = {
      "Skin Disease": FontAwesomeIcons.handSparkles,
      "Respiratory Disease": FontAwesomeIcons.lungs,
      "Digestive Disease": FontAwesomeIcons.utensils,
      "Liver Disease": FontAwesomeIcons.prescriptionBottle,
      "Allergic Reaction": FontAwesomeIcons.biohazard,
      "Immune System Disease": FontAwesomeIcons.shieldVirus,
      "Metabolic Disease": FontAwesomeIcons.fire,
      "Cardiovascular Disease": FontAwesomeIcons.heartPulse,
      "Neurological Disease": FontAwesomeIcons.brain,
      "Musculoskeletal Disease": FontAwesomeIcons.dumbbell,
      "Parasitic Disease": FontAwesomeIcons.bug,
      "Viral Infection": FontAwesomeIcons.virus,
      "Bacterial Infection": FontAwesomeIcons.bacteria,
      "Endocrine Disorder": FontAwesomeIcons.dna,
      "Urinary System Disease": FontAwesomeIcons.water,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Category',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontFamily: 'Raleway',
          ),
        ),
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
      ),
      body: FutureBuilder<CategoryResponse>(
        future: apiService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.deepPurple));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          } else {
            List<String> categories = snapshot.data!.categories;
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 items per row
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1, // Slightly taller
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                String category = categories[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SymptomScreen(category: categories[index]),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          spreadRadius: 2,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor:
                              AppColors.deepPurple.withOpacity(0.1),
                          child: Icon(
                            diseaseIcons[category] ?? FontAwesomeIcons.question,
                            size: 32,
                            color: AppColors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          category,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(fontSize: 14),
                        ),
                      ],
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

class _SymptomScreenState extends State<SymptomScreen>
    with SingleTickerProviderStateMixin {
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
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  meaning ?? 'No meaning available.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
        title: const Text('Answer Symptoms',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'Raleway',
            )),
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        // 🔹 Set the back button color here
        iconTheme: const IconThemeData(
          color: Colors.white, // Change this to any color
        ),
      ),
      body: FutureBuilder<SymptomResponse>(
        future: apiService.getInitialSymptoms(widget.category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF8b5cf6)));
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
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF8b5cf6)));
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
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF8b5cf6)));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return Center(
                        child: Text('No details found for $currentSymptom.'));
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
                              child: Text.rich(
                                TextSpan(
                                  text: 'Do you have ', // Regular text
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Raleway',
                                  ),
                                  children: [
                                    TextSpan(
                                      text: currentSymptom,
                                      // Underlined text (Dynamic variable)
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Raleway',
                                        decoration: TextDecoration
                                            .underline, // Underline applied
                                      ),
                                    ),
                                    const TextSpan(text: '?'),
                                    // Regular text again
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    await handleSymptomResponse(
                                        apiService, true);
                                    _controller.reset();
                                    _controller.forward();
                                  },
                                  child: const Text('Yes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Raleway',
                                      )),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    await handleSymptomResponse(
                                        apiService, false);
                                    _controller.reset();
                                    _controller.forward();
                                  },
                                  child: const Text('No',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Raleway',
                                      )),
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

        // Save to Firestore when prediction stops
        _savePredictionToFirestore(response);
      } else {
        symptoms.insert(currentSymptomIndex, response.nextSymptom!);
      }
    });
  }

  Future<void> _savePredictionToFirestore(PredictionResponse response) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final User? user = _auth.currentUser;

    if (user != null) {
      // Get the top prediction
      final topPrediction = response.topPredictions.first;
      final disease = topPrediction.keys.first;
      final confidence = topPrediction.values.first;

      // Prepare symptoms list
      final symptomsList = currentSymptoms.entries
          .where((e) => e.value) // Only include symptoms answered "Yes"
          .map((e) => capitalize(e.key))
          .toList();

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('med_history')
          .add({
        'disease': disease,
        'confidence': confidence,
        'symptoms': symptomsList,
        'date': DateTime.now().toIso8601String(),
        'category': widget.category,
      });
    }
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Raleway',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${(response.confidence * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8b5cf6),
                      fontFamily: 'Raleway',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Top Predictions:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Raleway',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...response.topPredictions.map((prediction) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '${capitalize(prediction.keys.first)}: ${(prediction.values.first * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Raleway',
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),
                  Text('Questions Remaining: ${response.questionsRemaining}',style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Raleway',

                  ),),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                fontFamily: 'Raleway',

              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 300, // Increased height for better visibility
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  // Set max Y to 100 for percentage clarity
                  barGroups:
                      response.topPredictions.asMap().entries.map((entry) {
                    int index = entry.key;
                    var prediction = entry.value;
                    String disease = prediction.keys.first;
                    double confidence = prediction.values.first * 100;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: confidence,
                          color: const Color(0xFF8b5cf6).withOpacity(
                              0.8 + (index * 0.1)), // Gradient effect
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
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700],
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60, // Increased for rotated text
                        getTitlesWidget: (value, meta) {
                          String title =
                              response.topPredictions[value.toInt()].keys.first;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Transform.rotate(
                              angle: -45 * 3.14159 / 180, // Rotate 45 degrees
                              child: Text(
                                capitalize(title),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[800],
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Raleway',

                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      // Function returning color
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${(rod.toY).toStringAsFixed(1)}%',
                          const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold,
                            fontFamily: 'Raleway',
                          ),
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
