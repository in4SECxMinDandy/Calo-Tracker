// Passive Sleep Tracking Service
// Main service that coordinates passive sleep collection and inference
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/sleep_session_estimated.dart';
import 'passive_sleep_collector_service.dart';
import 'sleep_inference_engine.dart';

/// Main service for passive sleep tracking
class PassiveSleepService {
  static PassiveSleepService? _instance;
  static PassiveSleepService get instance => 
      _instance ??= PassiveSleepService._();
  
  PassiveSleepService._();
  
  // Sub-services
  final PassiveSleepCollectorService _collector = PassiveSleepCollectorService.instance;
  final SleepInferenceEngine _inference = SleepInferenceEngine.instance;
  
  // State
  bool _isEnabled = false;
  bool _isTracking = false;
  
  // Settings
  bool _collectAccelerometer = true;
  bool _collectScreenEvents = true;
  bool _collectChargingEvents = true;
  bool _collectBatteryEvents = true;
  
  // Callbacks
  Function(SleepSessionEstimated)? onSleepSessionDetected;
  Function(Map<String, dynamic>)? onStatusUpdate;
  
  /// Check if passive sleep tracking is enabled
  bool get isEnabled => _isEnabled;
  
  /// Check if currently tracking
  bool get isTracking => _isTracking;
  
  /// Get collector status
  Map<String, dynamic> get collectorStatus => _collector.getCurrentStatus();
  
  /// Get inference status
  Map<String, dynamic> get inferenceStatus => _inference.getStatus();
  
  /// Get estimated sessions
  List<SleepSessionEstimated> get estimatedSessions => _inference.estimatedSessions;
  
  /// Enable/disable passive sleep tracking
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    
    if (enabled) {
      await startTracking();
    } else {
      await stopTracking();
    }
  }
  
  /// Update settings
  void updateSettings({
    bool? accelerometer,
    bool? screenEvents,
    bool? chargingEvents,
    bool? batteryEvents,
  }) {
    if (accelerometer != null) _collectAccelerometer = accelerometer;
    if (screenEvents != null) _collectScreenEvents = screenEvents;
    if (chargingEvents != null) _collectChargingEvents = chargingEvents;
    if (batteryEvents != null) _collectBatteryEvents = batteryEvents;
    
    // Update collector config
    _collector.updateConfig(
      SleepCollectorConfig(
        enableAccelerometer: _collectAccelerometer,
        enableScreenEvents: _collectScreenEvents,
        enableChargingEvents: _collectChargingEvents,
        enableBatteryEvents: _collectBatteryEvents,
      ),
    );
  }
  
  /// Start passive sleep tracking
  Future<bool> startTracking() async {
    if (_isTracking) {
      debugPrint('[PassiveSleep] Already tracking');
      return true;
    }
    
    if (!_isEnabled) {
      debugPrint('[PassiveSleep] Not enabled');
      return false;
    }
    
    try {
      // Start inference engine
      _inference.onSleepSessionDetected = _handleSleepSessionDetected;
      _inference.onStatusUpdate = _handleStatusUpdate;
      await _inference.start();
      
      // Start collector
      _collector.onWindowAnalysis = _handleWindowAnalysis;
      await _collector.startCollecting(
        config: SleepCollectorConfig(
          enableAccelerometer: _collectAccelerometer,
          enableScreenEvents: _collectScreenEvents,
          enableChargingEvents: _collectChargingEvents,
          enableBatteryEvents: _collectBatteryEvents,
        ),
      );
      
      _isTracking = true;
      debugPrint('[PassiveSleep] Tracking started');
      
      return true;
    } catch (e) {
      debugPrint('[PassiveSleep] Error starting: $e');
      return false;
    }
  }
  
  /// Stop passive sleep tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;
    
    try {
      await _collector.stopCollecting();
      await _inference.stop();
      
      _isTracking = false;
      debugPrint('[PassiveSleep] Tracking stopped');
    } catch (e) {
      debugPrint('[PassiveSleep] Error stopping: $e');
    }
  }
  
  /// Handle window analysis from collector
  void _handleWindowAnalysis(Map<String, dynamic> analysis) {
    _inference.processWindowAnalysis(analysis);
  }
  
  /// Handle sleep session detected
  void _handleSleepSessionDetected(SleepSessionEstimated session) {
    debugPrint('[PassiveSleep] Detected: ${session.durationFormatted}');
    onSleepSessionDetected?.call(session);
  }
  
  /// Handle status update
  void _handleStatusUpdate(Map<String, dynamic> status) {
    onStatusUpdate?.call(status);
  }
  
  /// Analyze last night's sleep (morning routine)
  Future<SleepSessionEstimated?> analyzeLastNight() async {
    // This would analyze stored signals from last night
    // and return the estimated session
    final sessions = _inference.estimatedSessions;
    
    if (sessions.isEmpty) return null;
    
    // Return the most recent session
    return sessions.last;
  }
  
  /// Force trigger analysis for a time range
  Future<List<SleepSessionEstimated>> analyzeRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _inference.analyzeHistoricalRange(start, end);
  }
  
  /// Get current status for UI
  Map<String, dynamic> getCurrentStatus() {
    return {
      'isEnabled': _isEnabled,
      'isTracking': _isTracking,
      'collector': collectorStatus,
      'inference': inferenceStatus,
    };
  }
  
  /// Dispose resources
  void dispose() {
    stopTracking();
    _instance = null;
  }
}
