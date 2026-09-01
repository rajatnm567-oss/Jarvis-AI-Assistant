import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ⚙️ SETTINGS SCREEN - Configuration & Preferences
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late SharedPreferences _prefs;
  bool _darkMode = true;
  String _language = 'English';
  bool _notificationsEnabled = true;
  bool _voiceCommandsEnabled = true;
  bool _biometricAuth = false;
  double _textSize = 16;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 📂 Load Settings from SharedPreferences
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = _prefs.getBool('darkMode') ?? true;
      _language = _prefs.getString('language') ?? 'English';
      _notificationsEnabled = _prefs.getBool('notifications') ?? true;
      _voiceCommandsEnabled = _prefs.getBool('voiceCommands') ?? true;
      _biometricAuth = _prefs.getBool('biometric') ?? false;
      _textSize = _prefs.getDouble('textSize') ?? 16;
    });
  }

  /// 💾 Save Settings
  Future<void> _saveSetting(String key, dynamic value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Settings'),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🎨 APPEARANCE SECTION
            _buildSectionTitle('🎨 Appearance'),
            _buildSettingCard(
              title: 'Dark Mode',
              subtitle: _darkMode ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                  _saveSetting('darkMode', value);
                },
                activeColor: Colors.blue[600],
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'Language',
              subtitle: _language,
              onTap: () => _showLanguageDialog(),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'Text Size',
              subtitle: 'Current: ${_textSize.toStringAsFixed(0)}',
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: _textSize,
                  min: 12,
                  max: 24,
                  onChanged: (value) {
                    setState(() => _textSize = value);
                    _saveSetting('textSize', value);
                  },
                  activeColor: Colors.blue[600],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🔊 SOUND & NOTIFICATIONS
            _buildSectionTitle('🔊 Sound & Notifications'),
            _buildSettingCard(
              title: 'Push Notifications',
              subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _saveSetting('notifications', value);
                },
                activeColor: Colors.blue[600],
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'Voice Commands',
              subtitle: _voiceCommandsEnabled ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: _voiceCommandsEnabled,
                onChanged: (value) {
                  setState(() => _voiceCommandsEnabled = value);
                  _saveSetting('voiceCommands', value);
                },
                activeColor: Colors.blue[600],
              ),
            ),
            const SizedBox(height: 24),

            // 🔐 SECURITY
            _buildSectionTitle('🔐 Security'),
            _buildSettingCard(
              title: 'Biometric Authentication',
              subtitle: _biometricAuth ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: _biometricAuth,
                onChanged: (value) {
                  setState(() => _biometricAuth = value);
                  _saveSetting('biometric', value);
                },
                activeColor: Colors.blue[600],
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: () => _showPasswordDialog(),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'Device Trust',
              subtitle: 'Manage trusted devices',
              onTap: () => _showTrustedDevicesDialog(),
            ),
            const SizedBox(height: 24),

            // 📊 DATA & STORAGE
            _buildSectionTitle('📊 Data & Storage'),
            _buildSettingCard(
              title: 'Clear Cache',
              subtitle: 'Remove temporary files',
              onTap: () => _showClearCacheDialog(),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'Backup Data',
              subtitle: 'Backup to cloud',
              onTap: () => _showBackupDialog(),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'Storage Usage',
              subtitle: '2.5 GB / 10 GB used',
            ),
            const SizedBox(height: 24),

            // ℹ️ ABOUT
            _buildSectionTitle('ℹ️ About'),
            _buildSettingCard(
              title: 'App Version',
              subtitle: 'v1.0.0',
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'Privacy Policy',
              subtitle: 'View our privacy policy',
              onTap: () => _showPrivacyPolicy(),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'Terms of Service',
              subtitle: 'View terms and conditions',
              onTap: () => _showTermsOfService(),
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              title: 'About Jarvis AI',
              subtitle: 'Learn more about the app',
              onTap: () => _showAboutDialog(),
            ),
            const SizedBox(height: 24),

            // 🚪 LOGOUT
            ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout),
              label: const Text('🚪 Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 📌 Build Section Title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 🎨 Build Settings Card
  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null && onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
              ),
          ],
        ),
      ),
    );
  }

  /// 🌐 Show Language Dialog
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌐 Select Language'),
        backgroundColor: const Color(0xFF1A1A2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Hindi', 'Spanish', 'French']
              .map((lang) => ListTile(
                    title: Text(
                      lang,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      setState(() => _language = lang);
                      _saveSetting('language', lang);
                      Navigator.pop(context);
                    },
              ))
              .toList(),
        ),
      ),
    );
  }

  /// 🔑 Show Password Dialog
  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔑 Change Password'),
        backgroundColor: const Color(0xFF1A1A2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Current Password',
                filled: true,
                fillColor: Colors.grey[800],
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'New Password',
                filled: true,
                fillColor: Colors.grey[800],
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Password updated!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  /// 📱 Show Trusted Devices Dialog
  void _showTrustedDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📱 Trusted Devices'),
        backgroundColor: const Color(0xFF1A1A2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'My Phone',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Current Device',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.check, color: Colors.green),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// 🧹 Show Clear Cache Dialog
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧹 Clear Cache'),
        backgroundColor: const Color(0xFF1A1A2E),
        content: const Text(
          'Are you sure you want to clear all cached data?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Cache cleared!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  /// ☁️ Show Backup Dialog
  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('☁️ Backup Data'),
        backgroundColor: const Color(0xFF1A1A2E),
        content: const Text(
          'Backup all your tasks and settings to the cloud?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Backup started!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Backup'),
          ),
        ],
      ),
    );
  }

  /// 📋 Show Privacy Policy
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Privacy Policy'),
        backgroundColor: const Color(0xFF1A1A2E),
        content: SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. We collect minimal data and never share it with third parties. All data is encrypted and stored securely.',
            style: TextStyle(color: Colors.grey[300]),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agree'),
          ),
        ],
      ),
    );
  }

  /// 📜 Show Terms of Service
  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📜 Terms of Service'),
        backgroundColor: const Color(0xFF1A1A2E),
        content: SingleChildScrollView(
          child: Text(
            'By using Jarvis AI, you agree to our terms and conditions. Use the app responsibly and respect other users.',
            style: TextStyle(color: Colors.grey[300]),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// ℹ️ Show About Dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ℹ️ About Jarvis AI'),
        backgroundColor: const Color(0xFF1A1A2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jarvis AI Assistant',
              style: TextStyle(
                color: Colors.blue[300],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'An intelligent AI assistant powered by Google Gemini API with voice commands, task management, and cross-device sync.',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• AI-powered conversations\n• Voice commands (Hindi & English)\n• Task management with priorities\n• Cloud sync across devices\n• Real-time notifications\n• Self-healing capabilities',
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// 🚪 Show Logout Dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚪 Logout'),
        backgroundColor: const Color(0xFF1A1A2E),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Logout logic here
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
