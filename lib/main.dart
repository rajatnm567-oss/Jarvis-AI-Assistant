import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:upgrader/upgrader.dart';
import 'services/jarvis_ai_service.dart';
import 'services/voice_service.dart';
import 'services/self_repair_service.dart';
import 'services/multi_device_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/jarvis_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Sentry (Error Tracking & Self-Repair)
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      const ProviderScope(
        child: JarvisApp(),
      ),
    ),
  );
}

class JarvisApp extends ConsumerStatefulWidget {
  const JarvisApp({Key? key}) : super(key: key);

  @override
  ConsumerState<JarvisApp> createState() => _JarvisAppState();
}

class _JarvisAppState extends ConsumerState<JarvisApp> {
  @override
  void initState() {
    super.initState();
    _initializeJarvis();
  }

  Future<void> _initializeJarvis() async {
    try {
      // 🤖 Initialize AI Service
      await ref.read(jarvisAIServiceProvider.notifier).initialize();

      // 🎤 Initialize Voice Service (Hindi + English)
      await ref.read(voiceServiceProvider.notifier).initialize();

      // 🔧 Initialize Self-Repair System
      await ref.read(selfRepairServiceProvider.notifier).startMonitoring();

      // 📱 Initialize Multi-Device Sync
      await ref.read(multiDeviceServiceProvider.notifier).setupSync();

      // 📦 Check for Updates
      UpgradeAlert.show(context);

      print('✅ JARVIS AI INITIALIZED SUCCESSFULLY');
    } catch (e, stackTrace) {
      print('❌ Initialization Error: $e');
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(darkModeProvider);

    return MaterialApp(
      title: 'JARVIS - Iron Man AI Assistant',
      theme: isDarkMode ? JarvisTheme.darkTheme : JarvisTheme.lightTheme,
      home: const JarvisMainScreen(),
      navigatorObservers: [
        SentryNavigatorObserver(),
      ],
    );
  }
}

class JarvisMainScreen extends ConsumerStatefulWidget {
  const JarvisMainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<JarvisMainScreen> createState() => _JarvisMainScreenState();
}

class _JarvisMainScreenState extends ConsumerState<JarvisMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// 🔵 PROVIDERS (State Management)

final jarvisAIServiceProvider =
    StateNotifierProvider<JarvisAIService, AsyncValue<String>>((ref) {
  return JarvisAIService();
});

final voiceServiceProvider =
    StateNotifierProvider<VoiceService, AsyncValue<String>>((ref) {
  return VoiceService();
});

final selfRepairServiceProvider =
    StateNotifierProvider<SelfRepairService, AsyncValue<Map>>((ref) {
  return SelfRepairService();
});

final multiDeviceServiceProvider =
    StateNotifierProvider<MultiDeviceService, AsyncValue<List>>((ref) {
  return MultiDeviceService();
});

final darkModeProvider = StateProvider<bool>((ref) => false);

// 📊 FEATURE FLAGS
final featureFlagsProvider = StateProvider<Map<String, bool>>((ref) {
  return {
    'voice_commands': true,
    'ai_learning': true,
    'biometric_security': true,
    'multi_device_sync': true,
    'custom_sounds': true,
    'gaming_features': true,
    'siri_integration': true,
    'gemini_integration': true,
    'cloud_sync': true,
    'auto_update': true,
    'self_repair': true,
  };
});
