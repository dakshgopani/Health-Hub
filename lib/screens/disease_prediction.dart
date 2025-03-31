import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // For bar chart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
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
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String userName = FirebaseAuth.instance.currentUser?.displayName ?? '';
  final String userEmail = FirebaseAuth.instance.currentUser!.email ?? "Email";
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildHeader(context),
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
                          style: AppTextStyles.body.copyWith(
                              fontSize: 14,
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w700),
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

  Widget _buildHeader(BuildContext context) {
    // Set the status bar color to match AppBar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: AppColors.deepPurple, // Make status bar color deep purple
      statusBarIconBrightness: Brightness.light, // White icons
    ));
    return AppBar(
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(
        color: Colors.white,
        weight: 900,
        size: 26,
      ),
      title: const Text(
        'Select Category',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'Raleway',
        ),
      ),
      backgroundColor: AppColors.deepPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
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
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Meaning of $symptom',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Raleway',
                    color: AppColors.textPurple,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  meaning ?? 'No meaning available.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontFamily: 'Raleway',
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.bold,
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
      backgroundColor: AppColors.backgroundPurple,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildHeader(context),
      ),
      body: FutureBuilder<SymptomResponse>(
        future: apiService.getInitialSymptoms(widget.category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.deepPurple,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading symptoms...',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.symptoms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.healing_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No symptoms found for this category.',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.deepPurple,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Analyzing your symptoms...',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData) {
                    return const Center(
                      child: Text(
                        'No prediction result.',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
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
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FutureBuilder<Map<String, String>>(
                  future: apiService.fetchSymptomDetails(currentSymptom),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.deepPurple,
                          strokeWidth: 3,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData) {
                      return Center(
                        child: Text(
                          'No details found for $currentSymptom.',
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } else {
                      symptomDetails[currentSymptom] = snapshot.data!;
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                      AppColors.deepPurple.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Question ${20 - remainingQuestions + 1} of 20',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Raleway',
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    GestureDetector(
                                      onTap: () {
                                        _showMeaningDialog(
                                          currentSymptom,
                                          symptomDetails[currentSymptom]![
                                          'meaning'],
                                        );
                                      },
                                      child: Text.rich(
                                        TextSpan(
                                          text: 'Do you have ',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontFamily: 'Raleway',
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                            height: 1.4,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: currentSymptom,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontFamily: 'Raleway',
                                                color: AppColors.deepPurple,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                TextDecoration.underline,
                                              ),
                                            ),
                                            const TextSpan(text: '?'),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '(Tap the symptom for more information)',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Raleway',
                                          color: Colors.grey[500],
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 40),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        _buildResponseButton(
                                          text: 'Yes',
                                          isPositive: true,
                                          onPressed: () async {
                                            await handleSymptomResponse(
                                                apiService, true);
                                            _controller.reset();
                                            _controller.forward();
                                          },
                                        ),
                                        const SizedBox(width: 24),
                                        _buildResponseButton(
                                          text: 'No',
                                          isPositive: false,
                                          onPressed: () async {
                                            await handleSymptomResponse(
                                                apiService, false);
                                            _controller.reset();
                                            _controller.forward();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildResponseButton({
    required String text,
    required bool isPositive,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPositive ? AppColors.deepPurple : Colors.white,
        foregroundColor: isPositive ? Colors.white : AppColors.deepPurple,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: isPositive
              ? BorderSide.none
              : const BorderSide(color: AppColors.deepPurple, width: 2),
        ),
        elevation: isPositive ? 4 : 0,
        shadowColor: isPositive
            ? AppColors.deepPurple.withOpacity(0.5)
            : Colors.transparent,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'Raleway',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Set the status bar color to match AppBar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.deepPurple,
      statusBarIconBrightness: Brightness.light,
    ));
    return AppBar(
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(
        color: Colors.white,
        weight: 900,
        size: 26,
      ),
      title: const Text(
        'Answer Symptoms',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'Raleway',
        ),
      ),
      backgroundColor: AppColors.deepPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
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

class PredictionResult extends StatefulWidget {
  final PredictionResponse response;

  PredictionResult({required this.response});

  @override
  _PredictionResultState createState() => _PredictionResultState();
}

class _PredictionResultState extends State<PredictionResult>
    with SingleTickerProviderStateMixin {
  Map<String, String>? diseaseDetails;
  bool isLoadingDetails = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fetchDiseaseDetails();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchDiseaseDetails() async {
    ApiService apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final details = await apiService
          .generateDiseaseDetails(widget.response.predictedDisease);
      setState(() {
        diseaseDetails = details;
        isLoadingDetails = false;
      });
    } catch (e) {
      setState(() {
        isLoadingDetails = false;
      });
      print('Error fetching disease details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepPurple.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.veryLightPurple,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.medical_information_outlined,
                          color: AppColors.deepPurple,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Predicted Disease',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Raleway',
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              capitalize(widget.response.predictedDisease),
                              style: const TextStyle(
                                fontSize: 22,
                                fontFamily: 'Raleway',
                                color: AppColors.textPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildConfidenceIndicator(widget.response.confidence),
                  const SizedBox(height: 24),
                  const Text(
                    'Top Predictions:',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.response.topPredictions.map((prediction) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildPredictionItem(
                      disease: prediction.keys.first,
                      confidence: prediction.values.first,
                    ),
                  )),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Questions Remaining:',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${widget.response.questionsRemaining}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.response.shouldStop)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.red[400],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reason to Stop: ${widget.response.reasonToStop}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Raleway',
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Prediction Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.bold,
                color: AppColors.textPurple,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 350,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepPurple.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barGroups: widget.response.topPredictions
                      .asMap()
                      .entries
                      .map((entry) {
                    int index = entry.key;
                    var prediction = entry.value;
                    String disease = prediction.keys.first;
                    double confidence = prediction.values.first * 100;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: confidence,
                          color: index == 0
                              ? AppColors.deepPurple
                              : AppColors.lightPurple.withOpacity(
                            1.0 - (index * 0.2),
                          ),
                          width: 22,
                          borderRadius: BorderRadius.circular(8),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: Colors.grey[200],
                          ),
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
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Raleway',
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 70,
                        getTitlesWidget: (value, meta) {
                          String title = widget.response
                              .topPredictions[value.toInt()].keys.first;
                          return Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Transform.rotate(
                              angle: -45 * 3.14159 / 180,
                              child: Text(
                                capitalize(title),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Raleway',
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          AppColors.deepPurple.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${(rod.toY).toStringAsFixed(1)}%',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Raleway',
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (widget.response.shouldStop) ...[
              const SizedBox(height: 32),
              const Text(
                'Disease Details',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPurple,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepPurple.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isLoadingDetails
                    ? Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.deepPurple,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading disease details...',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
                    : diseaseDetails != null
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: diseaseDetails!.entries.map((entry) {
                    return Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.veryLightPurple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Raleway',
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w700,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
                    : Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load disease details.',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    final percentage = (confidence * 100).toStringAsFixed(1);
    final color = confidence > 0.7
        ? Colors.green[700]
        : confidence > 0.4
        ? Colors.orange[700]
        : Colors.red[700];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Confidence Level',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              height: 10,
              width: MediaQuery.of(context).size.width * confidence * 0.7,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color!.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPredictionItem(
      {required String disease, required double confidence}) {
    final percentage = (confidence * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              capitalize(disease),
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.veryLightPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.bold,
                color: AppColors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String capitalize(String symptom) {
    return symptom
        .split('_')
        .map((word) =>
    word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}