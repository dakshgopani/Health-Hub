import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HealthChatbotScreen extends StatefulWidget {
  const HealthChatbotScreen({Key? key}) : super(key: key);

  @override
  _HealthChatbotScreenState createState() => _HealthChatbotScreenState();
}

class _HealthChatbotScreenState extends State<HealthChatbotScreen>
    with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  late GenerativeModel _model;
  late ChatSession _chat;
  late AnimationController _typingController;
  late stt.SpeechToText _speech;
  FlutterTts flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  String? _currentSpeechText;
  List<List<ChatMessage>> _previousChats = [];

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadPreviousChats();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _speech = stt.SpeechToText();
    _initializeTts();
    _addInitialMessage();
  }

  @override
  void dispose() {
    _typingController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _initializeGemini() {
    const apiKey =
        'AIzaSyCi7gsia_dPHgmgEY2kuKq2pD8Yf2pnMTM'; // Replace with your actual API key
    final configuration = GenerationConfig(
      temperature: 0.7,
      topK: 1,
      topP: 1,
      maxOutputTokens: 2048,
    );

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: configuration,
    );

    _chat = _model.startChat(history: [
      Content('user', [
        TextPart(
            'You are a strict health-focused chatbot. Only answer health-related questions. If asked about coding, mathematics, or unrelated topics, politely refuse. Maintain chat history for better context-based responses.')
      ]),
      Content('model', [
        TextPart(
            'Understood. I will answer only health-related questions and maintain context. I will politely refuse unrelated topics.')
      ]),
    ]);
  }

  void _initializeTts() {
    flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
        _isPaused = false;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
        _currentSpeechText = null;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        _isSpeaking = false;
        _isPaused = true;
      });
    });
  }

  void _addInitialMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text:
        "Hello! I'm MediBot, your health assistant. How can I help you today?",
        isUser: false,
        typingController: _typingController,
      ));
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() {
      _messages.insert(
          0,
          ChatMessage(
            text: text,
            isUser: true,
            typingController: _typingController,
          ));
      _messages.insert(
          0,
          ChatMessage(
            text: '...',
            isUser: false,
            isTyping: true,
            typingController: _typingController,
          ));
    });

    try {
      final response =
      await _chat.sendMessage(Content('user', [TextPart(text)]));
      final responseText =
      _cleanText(response.text ?? "I'm unable to process that.");

      if (_isUnrelatedQuery(text)) {
        setState(() {
          _messages.removeAt(0);
          _messages.insert(
              0,
              ChatMessage(
                text:
                "I can only discuss health-related topics. Please ask me something related to health.",
                isUser: false,
                typingController: _typingController,
              ));
        });
      } else {
        setState(() {
          _messages.removeAt(0);
          _messages.insert(
              0,
              ChatMessage(
                text: responseText,
                isUser: false,
                typingController: _typingController,
              ));
          _speakResponse(responseText);
        });
      }
      // Remove _saveCurrentChat() from here
    } catch (e) {
      _handleError("Error: ${e.toString()}");
    }
  }

  String _cleanText(String text) {
    return text.replaceAll('', '');
  }

  bool _isUnrelatedQuery(String query) {
    final List<String> forbiddenTopics = [
      "code",
      "math",
      "programming",
      "AI",
      "science",
      "physics",
      "history",
      "technology"
    ];
    return forbiddenTopics.any((topic) => query.toLowerCase().contains(topic));
  }

  void _handleError(String errorMessage) {
    setState(() {
      _messages.removeAt(0);
      _messages.insert(
          0,
          ChatMessage(
            text: "I encountered an error. Please try again later.",
            isUser: false,
            typingController: _typingController,
          ));
    });
    print(errorMessage);
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _speakResponse(String text) async {
    if (_isSpeaking && !_isPaused) {
      await flutterTts.stop();
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    } else if (!_isSpeaking) {
      _currentSpeechText = text;
      await flutterTts.speak(text);
    }
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking && !_isPaused) {
      await flutterTts.pause();
    } else if (_isPaused && _currentSpeechText != null) {
      await flutterTts.stop();
      await flutterTts.speak(_currentSpeechText!);
    }
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _saveCurrentChat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_messages.isNotEmpty) {
      List<String> chats = _previousChats.map((chat) {
        return jsonEncode(chat.map((msg) => msg.toJson()).toList());
      }).toList();
      await prefs.setStringList('chat_history', chats);
    }
  }

  Future<void> _loadPreviousChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedChats = prefs.getStringList('chat_history');
    if (savedChats != null) {
      setState(() {
        _previousChats = savedChats.map((chat) {
          final decoded = jsonDecode(chat) as List;
          return decoded
              .map((msg) => ChatMessage.fromJson(msg, _typingController))
              .toList();
        }).toList();
        // Only load messages if there's no current chat
        if (_messages.isEmpty && _previousChats.isNotEmpty) {
          _messages.addAll(_previousChats[0]);
        }
      });
    }
  }

  void _startNewChat() {
    setState(() {
      if (_messages.isNotEmpty) {
        // Save current chat only when starting new chat
        _previousChats.insert(0, List.from(_messages));
        if (_previousChats.length > 10) _previousChats.removeLast();
        _saveCurrentChat();
      }
      _messages.clear();
      _addInitialMessage();
      _chat = _model.startChat(history: []); // Reset chat context
    });
  }

// Update _handleSubmitted to remove the save call
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "MediBot",
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E77FF), Color(0xFFAA99FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _startNewChat,
            tooltip: 'Start New Chat',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE2E7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _messages[index],
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E77FF), Color(0xFFAA99FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    "Chat History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(_previousChats.length, (i) {
              return ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFF8E77FF)),
                title: Text(
                  "Chat ${i + 1} - ${_previousChats[i].first.text.length > 10 ? _previousChats[i].first.text.substring(0, 10) + '...' : _previousChats[i].first.text}",
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _messages.clear();
                    _messages.addAll(_previousChats[i]);
                    _chat = _model.startChat(
                        history: _previousChats[i]
                            .map((msg) => Content(msg.isUser ? 'user' : 'model',
                            [TextPart(msg.text)]))
                            .toList());
                  });
                  Navigator.pop(context);
                },
                hoverColor: Colors.grey[100],
              );
            }),
            ListTile(
              leading: const Icon(Icons.add, color: Color(0xFF8E77FF)),
              title: const Text(
                "Start New Chat",
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                _startNewChat();
                Navigator.pop(context);
              },
              hoverColor: Colors.grey[100],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: const Color(0xFF8E77FF),
                  size: 28,
                ),
                onPressed: _isListening ? _stopListening : _startListening,
                tooltip: 'Voice Input',
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: "Type your health question...",
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontFamily: 'Raleway',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isPaused ? Icons.play_arrow : Icons.pause,
                  color: const Color(0xFF8E77FF),
                  size: 28,
                ),
                onPressed: _toggleSpeech,
                tooltip: _isPaused ? 'Restart Speech' : 'Pause Speech',
              ),
              IconButton(
                icon:
                const Icon(Icons.send, color: Color(0xFF8E77FF), size: 28),
                onPressed: () => _handleSubmitted(_textController.text),
                tooltip: 'Send',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.typingController,
    this.isTyping = false,
    Key? key,
  }) : super(key: key);

  final String text;
  final bool isUser;
  final bool isTyping;
  final AnimationController typingController;

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'isTyping': isTyping,
  };

  factory ChatMessage.fromJson(
      Map<String, dynamic> json, AnimationController controller) =>
      ChatMessage(
        text: json['text'],
        isUser: json['isUser'],
        isTyping: json['isTyping'] ?? false,
        typingController: controller,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF8E77FF),
              child:
              Icon(Icons.medical_services, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isUser
                      ? [const Color(0xFFAA99FF), const Color(0xFF8E77FF)]
                      : [const Color(0xFF8E77FF), const Color(0xFF6B5BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isTyping
                  ? _buildTypingIndicator()
                  : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Raleway',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFAA99FF),
              child: Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        const SizedBox(width: 8),
        _buildDot(200),
        const SizedBox(width: 8),
        _buildDot(400),
      ],
    );
  }

  Widget _buildDot(int delay) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: typingController,
        curve:
        Interval(delay / 800, (delay + 400) / 800, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}