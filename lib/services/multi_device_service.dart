import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

/// 📱 MULTI-DEVICE SERVICE - Cross-Device Sync & Control
class MultiDeviceService extends StateNotifier<AsyncValue<Map>> {
  final logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic> _devices = {};
  StreamSubscription? _deviceListener;

  MultiDeviceService() : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Setup real-time device listener
      _setupDeviceListener();

      // Register current device
      await _registerDevice();

      logger.i('✅ Multi-Device Service Initialized');
      state = AsyncValue.data(_devices);
    } catch (e, stackTrace) {
      logger.e('❌ Init Error: $e', error: e, stackTrace: stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 📱 Register Current Device
  Future<void> _registerDevice() async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final deviceInfo = {
        'device_id': UniqueKey().toString(),
        'device_name': 'Your Device',
        'platform': 'Android/iOS',
        'last_seen': DateTime.now(),
        'is_active': true,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .add(deviceInfo);

      _devices['current'] = deviceInfo;
      logger.i('✅ Device registered');
    } catch (e) {
      logger.e('❌ Register Device Error: $e');
    }
  }

  /// 🔄 Setup Real-Time Device Listener
  void _setupDeviceListener() {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      _deviceListener = _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .snapshots()
          .listen((snapshot) {
        _devices.clear();
        for (var doc in snapshot.docs) {
          _devices[doc.id] = doc.data();
        }
        state = AsyncValue.data(_devices);
        logger.i('✅ Devices synced: ${_devices.length}');
      });
    } catch (e) {
      logger.e('❌ Device Listener Error: $e');
    }
  }

  /// 📤 Send Command to Another Device
  Future<void> sendCommandToDevice(
    String targetDeviceId,
    String command,
    Map<String, dynamic> parameters,
  ) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('device_commands')
          .add({
        'target_device_id': targetDeviceId,
        'command': command,
        'parameters': parameters,
        'timestamp': DateTime.now(),
        'status': 'pending',
      });

      logger.i('✅ Command sent to $targetDeviceId: $command');
    } catch (e) {
      logger.e('❌ Send Command Error: $e');
    }
  }

  /// 📥 Listen for Commands
  Stream<Map> listenForCommands() {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('device_commands')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : {};
      });
    } catch (e) {
      logger.e('❌ Listen Commands Error: $e');
      return Stream.value({});
    }
  }

  /// 🔗 Sync Data Across Devices
  Future<void> syncDataAcrossDevices(String dataType, Map data) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sync_data')
          .add({
        'data_type': dataType,
        'data': data,
        'synced_at': DateTime.now(),
        'synced_devices': _devices.keys.toList(),
      });

      logger.i('✅ Data synced: $dataType');
    } catch (e) {
      logger.e('❌ Sync Data Error: $e');
    }
  }

  /// 🎮 Remote Control Device
  Future<void> remoteControl(
    String targetDeviceId,
    String action,
  ) async {
    try {
      await sendCommandToDevice(
        targetDeviceId,
        'REMOTE_CONTROL',
        {'action': action},
      );
      logger.i('✅ Remote control sent: $action');
    } catch (e) {
      logger.e('❌ Remote Control Error: $e');
    }
  }

  /// 📊 Get Connected Devices
  List<Map> getConnectedDevices() {
    return _devices.values.toList();
  }

  /// 🔐 Security: Verify Device Trust
  Future<bool> verifyDeviceTrust(String deviceId) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trusted_devices')
          .doc(deviceId)
          .get();

      return doc.exists;
    } catch (e) {
      logger.e('❌ Verify Trust Error: $e');
      return false;
    }
  }

  /// ✅ Trust New Device
  Future<void> trustDevice(String deviceId) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('trusted_devices')
          .doc(deviceId)
          .set({
        'device_id': deviceId,
        'trusted_at': DateTime.now(),
        'is_trusted': true,
      });

      logger.i('✅ Device trusted: $deviceId');
    } catch (e) {
      logger.e('❌ Trust Device Error: $e');
    }
  }

  /// 🧹 Cleanup
  void dispose() {
    _deviceListener?.cancel();
    logger.i('🗑️ Multi-Device Service disposed');
  }
}

// Provider
final multiDeviceServiceProvider =
    StateNotifierProvider<MultiDeviceService, AsyncValue<Map>>((ref) {
  return MultiDeviceService();
});

import 'package:flutter/foundation.dart';
