import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_firestore/firebase_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// 🤖 JARVIS AI SERVICE - Google Gemini Integration
class JarvisAIService extends StateNotifier<AsyncValue<String>> {
  final logger = Logger();
  late GenerativeModel _model;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> _conversationHistory = [];

  JarvisAIService() : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      const apiKey = 'YOUR_GEMINI_API_KEY';
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: apiKey,
      );

      // Load conversation history from Firestore
      await _loadConversationHistory();
      logger.i('✅ JARVIS AI Service Initialized');
      state = const AsyncValue.data('JARVIS Ready');
    } catch (e, stackTrace) {
      logger.e('❌ Initialization Error: $e', error: e, stackTrace: stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 🎤 Process voice command and return AI response
  Future<String> processCommand(String userCommand) async {
    try {
      logger.d('🎤 Processing: $userCommand');

      // Add to conversation history
      _conversationHistory.add('User: $userCommand');

      // Build Jarvis-style prompt
      final prompt = _buildJarvisPrompt(userCommand);

      // Get response from Gemini
      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      final aiResponse = response.text ?? 'Sorry, I did not understand that.';

      // Add to history
      _conversationHistory.add('Jarvis: $aiResponse');

      // Save to Firestore
      await _saveToHistory(userCommand, aiResponse);

      logger.i('✅ Response: $aiResponse');
      state = AsyncValue.data(aiResponse);
      return aiResponse;
    } catch (e, stackTrace) {
      logger.e('❌ Error: $e', error: e, stackTrace: stackTrace);
      state = AsyncValue.error(e, stackTrace);
      return 'I encountered an error. Please try again.';
    }
  }

  /// 📋 Process task-related commands
  Future<String> processTaskCommand(String command) async {
    try {
      final taskPrompt = '''
        You are JARVIS, an AI assistant. The user wants to manage tasks.
        
        User Command: $command
        
        Possible actions:
        - Add task
        - Remove task
        - List tasks
        - Update task
        - Set reminder
        
        Respond with action and details in JSON format:
        {"action": "...", "task_title": "...", "priority": "high/medium/low", "due_date": "..."}
      ''';

      final response = await _model.generateContent([
        Content.text(taskPrompt),
      ]);

      return response.text ?? '';
    } catch (e) {
      logger.e('❌ Task Command Error: $e');
      return '';
    }
  }

  /// 🧠 Custom AI Training (Learn user preferences)
  Future<void> trainAI(String userInput, String expectedOutput) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> trainingData =
          prefs.getStringList('ai_training_data') ?? [];

      trainingData.add('$userInput|$expectedOutput');
      await prefs.setStringList('ai_training_data', trainingData);

      logger.i('✅ AI Training Updated');
    } catch (e) {
      logger.e('❌ Training Error: $e');
    }
  }

  /// 💾 Save conversation to Firestore
  Future<void> _saveToHistory(String userInput, String aiOutput) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('conversation_history')
          .add({
        'user_input': userInput,
        'ai_output': aiOutput,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      logger.e('❌ Save History Error: $e');
    }
  }

  /// 📖 Load conversation history from Firestore
  Future<void> _loadConversationHistory() async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('conversation_history')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _conversationHistory.clear();
      for (var doc in snapshot.docs) {
        _conversationHistory.add('User: ${doc['user_input']}');
        _conversationHistory.add('Jarvis: ${doc['ai_output']}');
      }
      logger.i('✅ History Loaded: ${_conversationHistory.length} items');
    } catch (e) {
      logger.e('❌ Load History Error: $e');
    }
  }

  /// 🎨 Build Jarvis-style prompt
  String _buildJarvisPrompt(String userCommand) {
    return '''
      You are JARVIS, an advanced AI assistant inspired by Iron Man's AI.
      
      Characteristics:
      - Professional and sophisticated
      - Quick and concise responses (max 2 sentences for voice)
      - Always helpful and proactive
      - Witty but respectful
      - Reference yourself as "JARVIS"
      
      Conversation History (Recent):
      ${_conversationHistory.sublist(0, min(10, _conversationHistory.length)).join('\n')}
      
      User Command: $userCommand
      
      Respond naturally and helpfully.
    ''';
  }

  /// 🔄 Clear history
  void clearHistory() {
    _conversationHistory.clear();
    logger.i('🗑️ History cleared');
  }

  /// 📊 Get analytics
  Map<String, dynamic> getAnalytics() {
    return {
      'total_interactions': _conversationHistory.length ~/ 2,
      'last_updated': DateTime.now(),
      'status': 'active',
    };
  }
}

// Provider
final jarvisAIServiceProvider =
    StateNotifierProvider<JarvisAIService, AsyncValue<String>>((ref) {
  return JarvisAIService();
});

/// Helper function
int min(int a, int b) => a < b ? a : b;
