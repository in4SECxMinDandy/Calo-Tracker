// Passive Sleep Collector Service
// Collects phone sensor signals for passive sleep estimation
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../models/sleep_signal_event.dart';
import '../storage_service.dart';

/// Configuration for sleep signal collection
class SleepCollectorConfig {
  /// Window size for analyzing sleep (in minutes)
  final int windowSizeMinutes;
  
  /// Accelerometer sampling interval (milliseconds)
  final int accelerometerSampleIntervalMs;
  
  /// Minimum motion threshold for "still" detection
  final double motionThreshold;
  
  /// Enable/disable each signal type
  final bool enableAccelerometer;
  final bool enableScreenEvents;
  final bool enableChargingEvents;
  final bool enableBatteryEvents;
  final bool enableUsageStats;
  
  const SleepCollectorConfig({
    this.windowSizeMinutes = 5,
    this.accelerometerSampleIntervalMs = 1000, // 1 second between samples
    this.motionThreshold = 0.1, // Very low = very still
    this.enableAccelerometer = true,
    this.enableScreenEvents = true,
    this.enableChargingEvents = true,
    this.enableBatteryEvents = true,
    this.enableUsageStats = false, // Requires special permission
  });
  
  static const SleepCollectorConfig defaultConfig = SleepCollectorConfig();
}

/// Callback for new signal events
typedef SignalEventCallback = void Function(SleepSignalEvent event);

/// Callback for sleep window analysis results
typedef WindowAnalysisCallback = void Function(Map<String, dynamic> analysis);

/// Service that collects passive sleep signals from the phone
class PassiveSleepCollectorService {
  static PassiveSleepCollectorService? _instance;
  static PassiveSleepCollectorService get instance => 
      _instance ??= PassiveSleepCollectorService._();
  
  PassiveSleepCollectorService._();
  
  SleepCollectorConfig _config = SleepCollectorConfig.defaultConfig;
  bool _isCollecting = false;

  // Stream subscriptions
  // ignore: unused_field - Will be used when sensors_plus is added
  StreamSubscription<dynamic>? _accelerometerSubscription;
  MethodChannel? _platformChannel;
  
  // Event storage (in-memory buffer before saving to DB)
  final List<SleepSignalEvent> _eventBuffer = [];
  static const int _maxBufferSize = 1000;

  // Callbacks
  SignalEventCallback? onSignalEvent;
  WindowAnalysisCallback? onWindowAnalysis;

  // Accelerometer tracking
  final List<double> _motionReadings = [];
  DateTime? _lastMotionSample;
  // ignore: unused_field - Will be used in future enhancement
  double _lastMotionMagnitude = 0;

  // Current state tracking
  bool _wasScreenOn = true;
  bool _wasCharging = false;
  int _lastBatteryLevel = -1;
  
  /// Get current config
  SleepCollectorConfig get config => _config;
  
  /// Check if currently collecting
  bool get isCollecting => _isCollecting;
  
  /// Update configuration
  void updateConfig(SleepCollectorConfig newConfig) {
    _config = newConfig;
  }
  
  /// Start collecting sleep signals
  Future<bool> startCollecting({
    SleepCollectorConfig? config,
    SignalEventCallback? onSignal,
    WindowAnalysisCallback? onAnalysis,
  }) async {
    if (_isCollecting) {
      debugPrint('[SleepCollector] Already collecting');
      return true;
    }
    
    if (config != null) {
      _config = config;
    }
    
    onSignalEvent = onSignal;
    onWindowAnalysis = onAnalysis;
    
    try {
      // Initialize platform channel for Android broadcasts
      await _initPlatformChannel();
      
      // Start accelerometer listening if enabled
      if (_config.enableAccelerometer) {
        _startAccelerometerListening();
      }
      
      _isCollecting = true;
      debugPrint('[SleepCollector] Started collecting');
      
      // Start periodic window analysis
      _startWindowAnalysisTimer();
      
      return true;
    } catch (e) {
      debugPrint('[SleepCollector] Error starting: $e');
      return false;
    }
  }
  
  /// Stop collecting sleep signals
  Future<void> stopCollecting() async {
    if (!_isCollecting) return;
    
    _isCollecting = false;
    
    // Cancel subscriptions
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    
    // Cancel platform channel
    _platformChannel?.invokeMethod('stopListening');
    _platformChannel = null;
    
    // Save remaining buffer
    await _flushBuffer();
    
    debugPrint('[SleepCollector] Stopped collecting');
  }
  
  /// Initialize platform channel for Android-specific broadcasts
  Future<void> _initPlatformChannel() async {
    _platformChannel = const MethodChannel('com.calotracker/sleep_signals');
    
    try {
      // Set up method call handler
      _platformChannel?.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onScreenStateChanged':
            final isOn = call.arguments as bool;
            _handleScreenStateChange(isOn);
            break;
          case 'onChargingStateChanged':
            final isCharging = call.arguments as bool;
            _handleChargingStateChange(isCharging);
            break;
          case 'onBatteryLevelChanged':
            final level = call.arguments as int;
            _handleBatteryLevelChange(level);
            break;
        }
        return null;
      });
      
      // Start listening on Android side
      await _platformChannel?.invokeMethod('startListening');
    } catch (e) {
      debugPrint('[SleepCollector] Platform channel error (expected on iOS): $e');
    }
  }
  
  /// Start accelerometer listening
  void _startAccelerometerListening() {
    // sensors_plus will be available after adding dependency
    // For now, this is a placeholder that will be activated when package is added
    debugPrint('[SleepCollector] Accelerometer listening started (requires sensors_plus package)');
    
    // TODO: Uncomment when sensors_plus is added to pubspec.yaml
    // _accelerometerSubscription = accelerometerEventStream(
    //   samplingPeriod: Duration(milliseconds: _config.accelerometerSampleIntervalMs),
    // ).listen(
    //   (AccelerometerEvent event) {
    //     _handleAccelerometerEvent(event);
    //   },
    //   onError: (error) {
    //     debugPrint('[SleepCollector] Accelerometer error: $error');
    //   },
    // );
  }
  
  /// Handle accelerometer event (placeholder - update signature when sensors_plus added)
  // ignore: unused_element
  void _handleAccelerometerEvent(dynamic event) {
    final magnitude = sqrt(
      (event.x as double) * (event.x as double) + 
      (event.y as double) * (event.y as double) + 
      (event.z as double) * (event.z as double),
    );
    
    // Calculate deviation from gravity (~9.8)
    final deviation = (magnitude - 9.8).abs();
    
    // Store reading
    _motionReadings.add(deviation);
    if (_motionReadings.length > 60) {
      _motionReadings.removeAt(0); // Keep last 60 readings (1 minute at 1Hz)
    }
    
    _lastMotionMagnitude = deviation;
    _lastMotionSample = DateTime.now();
    
    // If significant motion detected, log it
    if (deviation > _config.motionThreshold) {
      _addSignalEvent(
        SleepSignalEvent(
          type: SleepSignalType.accelerometer,
          value: SignalValue.active,
          metadata: {
            'magnitude': magnitude,
            'deviation': deviation,
          },
        ),
      );
    }
  }
  
  /// Handle screen state change
  void _handleScreenStateChange(bool isScreenOn) {
    final value = isScreenOn ? SignalValue.screenOn : SignalValue.screenOff;
    
    // Only log state changes
    if (_wasScreenOn != isScreenOn) {
      _addSignalEvent(
        SleepSignalEvent(
          type: SleepSignalType.screenState,
          value: value,
        ),
      );
      _wasScreenOn = isScreenOn;
    }
  }
  
  /// Handle charging state change
  void _handleChargingStateChange(bool isCharging) {
    final value = isCharging ? SignalValue.charging : SignalValue.unplugged;
    
    // Only log state changes
    if (_wasCharging != isCharging) {
      _addSignalEvent(
        SleepSignalEvent(
          type: SleepSignalType.chargingState,
          value: value,
        ),
      );
      _wasCharging = isCharging;
    }
  }
  
  /// Handle battery level change
  void _handleBatteryLevelChange(int level) {
    if (_lastBatteryLevel != -1 && _lastBatteryLevel != level) {
      _addSignalEvent(
        SleepSignalEvent(
          type: SleepSignalType.batteryLevel,
          value: level > _lastBatteryLevel ? SignalValue.charging : SignalValue.unplugged,
          metadata: {
            'level': level,
            'delta': level - _lastBatteryLevel,
          },
        ),
      );
    }
    _lastBatteryLevel = level;
  }
  
  /// Add a signal event to buffer
  void _addSignalEvent(SleepSignalEvent event) {
    _eventBuffer.add(event);
    
    // Notify callback
    onSignalEvent?.call(event);
    
    // Flush if buffer is full
    if (_eventBuffer.length >= _maxBufferSize) {
      _flushBuffer();
    }
  }
  
  /// Flush event buffer to storage
  Future<void> _flushBuffer() async {
    if (_eventBuffer.isEmpty) return;
    
    final events = List<SleepSignalEvent>.from(_eventBuffer);
    _eventBuffer.clear();
    
    // Save to local storage
    try {
      await StorageService.saveSleepSignalEvents(events);
      debugPrint('[SleepCollector] Flushed ${events.length} events to storage');
    } catch (e) {
      debugPrint('[SleepCollector] Error flushing buffer: $e');
      // Re-add events on error
      _eventBuffer.insertAll(0, events);
    }
  }
  
  /// Start periodic window analysis timer
  Timer? _windowAnalysisTimer;
  
  void _startWindowAnalysisTimer() {
    _windowAnalysisTimer?.cancel();
    _windowAnalysisTimer = Timer.periodic(
      Duration(minutes: _config.windowSizeMinutes),
      (_) => _analyzeCurrentWindow(),
    );
  }
  
  /// Analyze current window and produce summary
  Future<void> _analyzeCurrentWindow() async {
    if (!_isCollecting) return;

    // Get events from the last window (for future filtering)
    // ignore: unused_local_variable
    final cutoff = DateTime.now().subtract(
      Duration(minutes: _config.windowSizeMinutes),
    );

    // Analyze motion readings
    double avgMotion = 0;
    if (_motionReadings.isNotEmpty) {
      avgMotion = _motionReadings.reduce((a, b) => a + b) / _motionReadings.length;
    }
    
    // Determine if mostly still
    final isMostlyStill = avgMotion < _config.motionThreshold;
    
    // Build analysis result
    final analysis = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'windowMinutes': _config.windowSizeMinutes,
      'avgMotion': avgMotion,
      'isMostlyStill': isMostlyStill,
      'wasScreenOff': !_wasScreenOn,
      'wasCharging': _wasCharging,
      'motionReadings': _motionReadings.length,
    };
    
    // Notify callback
    onWindowAnalysis?.call(analysis);
    
    debugPrint('[SleepCollector] Window analysis: still=$isMostlyStill, motion=${avgMotion.toStringAsFixed(3)}');
  }
  
  /// Get current motion status
  Map<String, dynamic> getCurrentStatus() {
    double avgMotion = 0;
    if (_motionReadings.isNotEmpty) {
      avgMotion = _motionReadings.reduce((a, b) => a + b) / _motionReadings.length;
    }
    
    return {
      'isCollecting': _isCollecting,
      'avgMotion': avgMotion,
      'isMostlyStill': avgMotion < _config.motionThreshold,
      'screenOn': _wasScreenOn,
      'charging': _wasCharging,
      'bufferSize': _eventBuffer.length,
      'lastMotionSample': _lastMotionSample?.toIso8601String(),
    };
  }
  
  /// Check if user appears to be sleeping based on current signals
  bool isUserProbablySleeping() {
    if (_motionReadings.isEmpty) return false;
    
    final avgMotion = _motionReadings.reduce((a, b) => a + b) / _motionReadings.length;
    final isStill = avgMotion < _config.motionThreshold;
    final screenOff = !_wasScreenOn;
    
    // User likely sleeping if still + screen off
    return isStill && screenOff;
  }
  
  /// Force flush buffer (for app lifecycle events)
  Future<void> flushBuffer() async {
    await _flushBuffer();
  }
  
  /// Clean up resources
  void dispose() {
    stopCollecting();
    _windowAnalysisTimer?.cancel();
    _instance = null;
  }
}
