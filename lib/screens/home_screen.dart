import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../services/jarvis_ai_service.dart';
import '../services/voice_service.dart';
import '../services/todo_service.dart';

/// 🏠 HOME SCREEN - Main UI with AI Chat & Voice Commands
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late TextEditingController _messageController;
  late AnimationController _jarvisAnimationController;
  bool _isListening = false;
  List<Map<String, String>> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _jarvisAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _jarvisAnimationController.dispose();
    super.dispose();
  }

  /// 🎤 Start Voice Listening
  void _startListening() async {
    final voiceService = ref.read(voiceServiceProvider.notifier);

    voiceService.startListening(
      onResult: (text) {
        setState(() {
          _messageController.text = text;
        });
      },
      onListeningStateChanged: (isListening) {
        setState(() {
          _isListening = isListening;
        });
      },
      language: 'en_US',
    );
  }

  /// 🛑 Stop Voice Listening
  void _stopListening() async {
    final voiceService = ref.read(voiceServiceProvider.notifier);
    await voiceService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  /// 📤 Send Message to Jarvis AI
  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;

    // Add user message to chat
    setState(() {
      _chatMessages.add({
        'role': 'user',
        'message': userMessage,
        'timestamp': DateTime.now().toString(),
      });
      _messageController.clear();
    });

    // Get AI response
    final jarvisService = ref.read(jarvisAiServiceProvider.notifier);
    try {
      final response = await jarvisService.chat(userMessage);

      setState(() {
        _chatMessages.add({
          'role': 'jarvis',
          'message': response,
          'timestamp': DateTime.now().toString(),
        });
      });

      // Speak response
      final voiceService = ref.read(voiceServiceProvider.notifier);
      await voiceService.speak(response, language: 'en_US');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 JARVIS AI Assistant'),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: Column(
          children: [
            // 🤖 Jarvis Animation & Status
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Jarvis Logo
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                        CurvedAnimation(
                          parent: _jarvisAnimationController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue[300]!,
                              Colors.cyan[300]!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '🤖',
                            style: TextStyle(fontSize: 60),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isListening ? '🎤 Listening...' : '👋 Hello! I am Jarvis',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'How can I help you today?',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 💬 Chat Messages
            Expanded(
              flex: 3,
              child: _chatMessages.isEmpty
                  ? Center(
                      child: Text(
                        'Start a conversation!',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final message =
                            _chatMessages[_chatMessages.length - 1 - index];
                        final isUser = message['role'] == 'user';

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.blue[700]
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message['message']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // 📝 Input & Voice Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 🎤 Voice Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onLongPress: _startListening,
                        onLongPressUp: _stopListening,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [Colors.red[400]!, Colors.red[600]!]
                                  : [Colors.blue[400]!, Colors.blue[600]!],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isListening
                                    ? Colors.red.withOpacity(0.5)
                                    : Colors.blue.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isListening
                        ? 'Release to stop listening'
                        : 'Hold to speak',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📝 Text Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[800],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send),
                          color: Colors.white,
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/todos');
        },
        label: const Text('📋 Tasks'),
        icon: const Icon(Icons.task_alt),
        backgroundColor: Colors.blue[600],
      ),
    );
  }
}
