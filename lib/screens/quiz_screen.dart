import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  List<Question> allQuestions = [];
  List<Question> currentQuestions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool quizCompleted = false;
  bool showSpinWheel = false;
  bool hasSpun = false;
  late StreamController<int> _selected;
  int? lastSpinResult;
  late ConfettiController _confettiController;
  late AnimationController _questionAnimationController;
  late Animation<double> _questionAnimation;

  String? selectedAnswer;
  bool isCorrect = false;

  final List<String> rewards = [
    'Gift Voucher ₹100',
    'Gift Voucher ₹50',
    'Gift Voucher ₹200',
    'Try Again',
    'Gift Voucher ₹500'
  ];

  final List<Color> wheelColors = [
    AppColors.deepPurple,
    AppColors.deepPurple.withOpacity(0.8),
    AppColors.deepPurple.withOpacity(0.6),
    AppColors.deepPurple.withOpacity(0.4),
    AppColors.deepPurple.withOpacity(0.9),
  ];

  @override
  void initState() {
    super.initState();
    _selected = StreamController<int>.broadcast();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));

    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _questionAnimation = CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeInOut,
    );

    loadQuestions();
  }

  @override
  void dispose() {
    _selected.close();
    _confettiController.dispose();
    _questionAnimationController.dispose();
    super.dispose();
  }

  Future<void> loadQuestions() async {
    try {
      String data = await rootBundle.loadString('assets/json/medicine_quiz_data.json');
      List<dynamic> jsonResult = json.decode(data);
      allQuestions = jsonResult.map((q) => Question.fromJson(q)).toList();
      allQuestions.shuffle(Random());
      currentQuestions = allQuestions.take(10).toList();
      setState(() {});
      _questionAnimationController.forward();
    } catch (e) {
      print('Error loading questions: $e');
      // For demo purposes, create some sample questions if loading fails
      allQuestions = List.generate(
        10,
            (index) => Question(
          question: "Sample question ${index + 1}?",
          options: ["Option A", "Option B", "Option C", "Option D"],
          answer: "Option A",
        ),
      );
      currentQuestions = allQuestions;
      setState(() {});
      _questionAnimationController.forward();
    }
  }

  void checkAnswer(String selectedAnswer) {
    setState(() {
      this.selectedAnswer = selectedAnswer;
      isCorrect = selectedAnswer == currentQuestions[currentQuestionIndex].answer;

      if (isCorrect) {
        score++;
      }

      // Animate out current question
      _questionAnimationController.reverse().then((_) => null).whenComplete(() {
        setState(() {
          if (currentQuestionIndex < currentQuestions.length - 1) {
            currentQuestionIndex++;
          } else {
            quizCompleted = true;
            if (score > 5) {
              showSpinWheel = true;
              Future.delayed(Duration(seconds: 1), () {
                autoSpinWheel();
              });
            }
          }
        });

        if (!quizCompleted) {
          _questionAnimationController.forward();
        }
      });
    });
  }

  void resetQuiz() {
    _questionAnimationController.reset();
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      quizCompleted = false;
      showSpinWheel = false;
      hasSpun = false;
      lastSpinResult = null;
      selectedAnswer = null;
    });
    loadQuestions();
  }

  void autoSpinWheel() {
    if (hasSpun) return;

    int randomIndex = Random().nextInt(rewards.length);
    setState(() {
      hasSpun = true;
      lastSpinResult = randomIndex;
    });

    _selected.add(randomIndex);
  }

  void showRewardDialog(int index) {
    bool isWinner = rewards[index] != 'Try Again';

    if (isWinner) {
      _confettiController.play();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Confetti animation (only if user wins)
              if (isWinner)
                Align(
                  alignment: Alignment.center,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive, // Explode from center
                    emissionFrequency: 0.08,
                    numberOfParticles: 50,
                    maxBlastForce: 20,
                    minBlastForce: 10,
                    gravity: 0.2,
                    colors: [
                      Colors.indigo,
                      Colors.purple,
                      Colors.pink,
                      Colors.amber,
                      Colors.cyan,
                    ],
                  ),
                ),

              // Popup Dialog
              AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: isWinner ? Colors.indigo[50] : Colors.red[50],
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isWinner ? Icons.celebration_rounded : Icons.error_outline_rounded,
                      color: isWinner ? Colors.indigo : Colors.red[800],
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isWinner ? 'Congratulations!' : 'Try Again',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isWinner ? Colors.indigo : Colors.red[800],
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      isWinner ? 'You won: ${rewards[index]}' : 'Please try again for another chance!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isWinner ? Colors.indigo : Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        resetQuiz();
                      },
                      child: const Text(
                        'OK',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: quizCompleted
                  ? (showSpinWheel ? _buildSpinWheel() : _buildResultScreen())
                  : _buildQuestionScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: AppColors.deepPurple, // Make status bar color deep purple
      statusBarIconBrightness: Brightness.light, // White icons
    ));
    return AppBar(
      elevation: 0,
      iconTheme: const IconThemeData(
        color: Colors.white,
        weight: 900,
        size: 26,
      ),
      title: Text(
        'Healthcare Quiz', // Updated title
        style: AppTextStyles.whiteHeading.copyWith(fontWeight: FontWeight.w900),
      ),
      backgroundColor: AppColors.deepPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );
  }

  Widget _buildQuestionScreen() {
    return FadeTransition(
      opacity: _questionAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(_questionAnimation),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${currentQuestionIndex + 1}/${currentQuestions.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Raleway',
                      color: AppColors.deepPurple,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.deepPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Score: $score',
                      style: AppTextStyles.whiteHeading.copyWith(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _buildQuestionCard(),
              const SizedBox(height: 25),
              _buildOptionsGrid(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildQuestionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      shadowColor: AppColors.deepPurple.withOpacity(0.2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.deepPurple,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.quiz_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              currentQuestions.isNotEmpty
                  ? currentQuestions[currentQuestionIndex].question
                  : "Loading...",
              textAlign: TextAlign.center,
              style: AppTextStyles.whiteHeading.copyWith(
                fontSize: 20,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsGrid() {
    if (currentQuestions.isEmpty) return Container();

    List<String> options = currentQuestions[currentQuestionIndex].options;

    return Expanded(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: options.length,
        itemBuilder: (context, index) {
          return _buildOptionCard(options[index], index);
        },
      ),
    );
  }

  Widget _buildOptionCard(String option, int index) {
    bool isSelected = selectedAnswer == option;
    bool isCorrectAnswer = option == currentQuestions[currentQuestionIndex].answer;

    Color cardColor;
    if (isSelected) {
      cardColor = isCorrect ? Colors.green : Colors.red;
    } else {
      cardColor = Colors.white;
    }

    return InkWell(
      onTap: () => checkAnswer(option),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepPurple.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.deepPurple.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              option,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.deepPurple,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: AppColors.deepPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              score > 5 ? Icons.emoji_events_rounded : Icons.school_rounded,
              size: 80,
              color: AppColors.deepPurple,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Quiz Completed!',
            style: AppTextStyles.heading.copyWith(
              fontSize: 28,
              color: AppColors.deepPurple,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            score > 5 ? 'Great job!' : 'Keep learning!',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              color: AppColors.deepPurple.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepPurple.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Score:',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.deepPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$score/${currentQuestions.length}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Raleway',
                    color: score > 5 ? AppColors.deepPurple : Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: resetQuiz,
            icon: const Icon(Icons.refresh_rounded,color: Colors.white,),
            label: Text('Restart Quiz', style: AppTextStyles.whiteHeading.copyWith(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinWheel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text(
          'Congratulations!',
          style: AppTextStyles.heading.copyWith(
            fontSize: 28,
            color: AppColors.deepPurple,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Spin the wheel to claim your reward',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Raleway',
            color: AppColors.deepPurple.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          height: 320,
          width: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.deepPurple.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FortuneWheel(
            selected: _selected.stream,
            animateFirst: false,
            physics: CircularPanPhysics(
              duration: const Duration(seconds: 1),
              curve: Curves.decelerate,
            ),
            onAnimationEnd: () {
              if (lastSpinResult != null) {
                showRewardDialog(lastSpinResult!);
              }
            },
            items: List.generate(
              rewards.length,
                  (index) => FortuneItem(
                child: Padding(
                  padding: const EdgeInsets.only(left: 40.0),
                  child: Text(
                    rewards[index],
                    style: AppTextStyles.whiteHeading.copyWith(
                      fontSize: 14,
                    ),
                  ),
                ),
                style: FortuneItemStyle(
                  color: wheelColors[index % wheelColors.length],
                  borderWidth: 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        if (!hasSpun)
          ElevatedButton.icon(
            onPressed: autoSpinWheel,
            icon: const Icon(Icons.touch_app_rounded),
            label: Text('Spin Now!', style: AppTextStyles.whiteHeading.copyWith(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: AppColors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        if (hasSpun)
          Text(
            'Spinning...',
            style: AppTextStyles.body.copyWith(
              color: AppColors.deepPurple,
            ),
          ),
      ],
    );
  }
}

class Question {
  final String question;
  final List<String> options;
  final String answer;

  Question(
      {required this.question, required this.options, required this.answer});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      options: List<String>.from(json['options']),
      answer: json['answer'],
    );
  }
}