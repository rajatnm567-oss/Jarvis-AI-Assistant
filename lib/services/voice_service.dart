import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';
import 'dart:async';

/// 🎤 VOICE SERVICE - Speech-to-Text & Text-to-Speech
class VoiceService extends StateNotifier<AsyncValue<String>> {
  final logger = Logger();
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  StreamController<String>? _partialResultsController;

  VoiceService() : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _speechToText = stt.SpeechToText();
      _flutterTts = FlutterTts();

      // Initialize Speech-to-Text
      bool available = await _speechToText.initialize(
        onError: (error) => logger.e('🎤 Error: $error'),
        onStatus: (status) => logger.i('🎤 Status: $status'),
      );

      if (!available) {
        throw Exception('Speech recognition not available');
      }

      // Initialize Text-to-Speech
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.8);

      logger.i('✅ Voice Service Initialized');
      state = const AsyncValue.data('Voice Ready');
    } catch (e, stackTrace) {
      logger.e('❌ Init Error: $e', error: e, stackTrace: stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 🎤 Start Listening (Hindi & English)
  Future<void> startListening({
    required Function(String) onResult,
    required Function(bool) onListeningStateChanged,
    String language = 'en_US',
  }) async {
    try {
      if (!_isListening) {
        _isListening = true;
        onListeningStateChanged(true);

        // Map language codes
        String localeId = language == 'hi' ? 'hi_IN' : 'en_US';

        await _speechToText.listen(
          onResult: (result) {
            logger.d('🎤 Recognized: ${result.recognizedWords}');
            onResult(result.recognizedWords);

            if (result.finalResult) {
              _isListening = false;
              onListeningStateChanged(false);
            }
          },
          localeId: localeId,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 30),
        );

        logger.i('✅ Listening started');
      }
    } catch (e) {
      logger.e('❌ Listen Error: $e');
      _isListening = false;
    }
  }

  /// 🛑 Stop Listening
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;
      logger.i('🛑 Listening stopped');
    } catch (e) {
      logger.e('❌ Stop Error: $e');
    }
  }

  /// 🗣️ Speak Text (Hindi & English)
  Future<void> speak(
    String text, {
    String language = 'en_US',
    double pitch = 1.0,
    double rate = 0.8,
  }) async {
    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.setPitch(pitch);
      await _flutterTts.setSpeechRate(rate);

      logger.d('🗣️ Speaking: $text');
      await _flutterTts.speak(text);

      state = AsyncValue.data('Speaking');
    } catch (e) {
      logger.e('❌ Speak Error: $e');
    }
  }

  /// 📝 Speech Recognition Status
  bool get isListening => _isListening;

  /// 🎙️ Start Recording with Partial Results
  Stream<String> recordWithPartialResults({
    String language = 'en_US',
  }) {
    _partialResultsController = StreamController<String>.broadcast();

    _speechToText.listen(
      onResult: (result) {
        _partialResultsController?.add(result.recognizedWords);
      },
      localeId: language == 'hi' ? 'hi_IN' : 'en_US',
    );

    return _partialResultsController!.stream;
  }

  /// 🎛️ Set Voice Parameters
  Future<void> setVoiceParameters({
    double pitch = 1.0,
    double rate = 0.8,
    double volume = 1.0,
  }) async {
    try {
      await _flutterTts.setPitch(pitch);
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.setVolume(volume);
      logger.i('✅ Voice parameters updated');
    } catch (e) {
      logger.e('❌ Parameter Error: $e');
    }
  }

  /// 🎵 Play Sound Effect
  Future<void> playSoundEffect(String effectType) async {
    try {
      // Play Jarvis startup sound, beep, etc.
      final soundMap = {
        'startup': 'assets/sounds/jarvis_startup.mp3',
        'listening': 'assets/sounds/mic_active.mp3',
        'done': 'assets/sounds/task_complete.mp3',
        'error': 'assets/sounds/error_beep.mp3',
      };

      final sound = soundMap[effectType];
      if (sound != null) {
        await _flutterTts.synthesizeToFile(
          'sound',
          sound,
        );
        logger.i('🔊 Sound played: $effectType');
      }
    } catch (e) {
      logger.e('❌ Sound Error: $e');
    }
  }

  /// 🌍 Set Language
  Future<void> setLanguage(String languageCode) async {
    try {
      final languageMap = {
        'en': 'en_US',
        'hi': 'hi_IN',
        'es': 'es_ES',
        'fr': 'fr_FR',
        'de': 'de_DE',
        'zh': 'zh_CN',
        'ja': 'ja_JP',
        'ar': 'ar_SA',
      };

      final locale = languageMap[languageCode] ?? 'en_US';
      await _flutterTts.setLanguage(locale);
      logger.i('✅ Language set to: $languageCode');
    } catch (e) {
      logger.e('❌ Language Error: $e');
    }
  }

  /// 🔊 Get Available Languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      return await _flutterTts.getLanguages as List<String>;
    } catch (e) {
      logger.e('❌ Get Languages Error: $e');
      return ['en_US', 'hi_IN'];
    }
  }

  /// 🧹 Cleanup
  void dispose() {
    _partialResultsController?.close();
    _flutterTts.stop();
    logger.i('🗑️ Voice Service disposed');
  }
}

// Provider
final voiceServiceProvider =
    StateNotifierProvider<VoiceService, AsyncValue<String>>((ref) {
  return VoiceService();
});
