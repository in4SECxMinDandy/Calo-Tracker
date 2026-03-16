// Sleep Inference Engine
// Analyzes collected signals to estimate sleep sessions using heuristic scoring
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/sleep_session_estimated.dart';

/// Configuration for sleep inference algorithm
class SleepInferenceConfig {
  /// Window size for scoring (minutes)
  final int windowSizeMinutes;
  
  /// Score threshold to start sleep
  final int thresholdStart;
  
  /// Score threshold to end sleep
  final int thresholdEnd;
  
  /// Minimum continuous sleep duration (minutes)
  final int minSleepDurationMinutes;
  
  /// Maximum awake gap inside sleep session (minutes)
  final int maxAwakeGapInsideSleep;
  
  /// Minimum score duration to confirm sleep start (minutes)
  final int minScoreDurationMinutes;
  
  /// Heuristic weights
  final int screenOffScore;
  final int chargingScore;
  final int lowMotionScore;
  final int inactivityScore;
  final int unlockPenalty;
  final int motionPenalty;
  
  const SleepInferenceConfig({
    this.windowSizeMinutes = 5,
    this.thresholdStart = 60,
    this.thresholdEnd = 40,
    this.minSleepDurationMinutes = 60,
    this.maxAwakeGapInsideSleep = 30,
    this.minScoreDurationMinutes = 10,
    this.screenOffScore = 30,
    this.chargingScore = 20,
    this.lowMotionScore = 30,
    this.inactivityScore = 20,
    this.unlockPenalty = 30,
    this.motionPenalty = 30,
  });
  
  static const SleepInferenceConfig defaultConfig = SleepInferenceConfig();
}

/// Represents a potential sleep period during analysis
class SleepPeriodCandidate {
  DateTime? startTime;
  DateTime? endTime;
  int totalScore = 0;
  int scoreCount = 0;
  final List<Map<String, dynamic>> windowScores = [];
  
  double get averageScore {
    if (scoreCount == 0) return 0;
    return totalScore / scoreCount;
  }
  
  int get durationMinutes {
    if (startTime == null || endTime == null) return 0;
    return endTime!.difference(startTime!).inMinutes;
  }
  
  bool get isValid {
    return startTime != null && 
           endTime != null && 
           durationMinutes >= 60 && // Minimum 1 hour
           averageScore >= 50;
  }
  
  int get confidenceScore {
    // Calculate confidence based on score and duration
    final scoreFactor = (averageScore / 100 * 50).clamp(0, 50).toInt();
    final durationFactor = (durationMinutes / 480 * 50).clamp(0, 50).toInt(); // 8 hours = max
    return (scoreFactor + durationFactor).clamp(0, 100);
  }
}

/// Engine that analyzes sleep signals and produces sleep session estimates
class SleepInferenceEngine {
  static SleepInferenceEngine? _instance;
  static SleepInferenceEngine get instance => 
      _instance ??= SleepInferenceEngine._();
  
  SleepInferenceEngine._();
  
  SleepInferenceConfig _config = SleepInferenceConfig.defaultConfig;
  bool _isRunning = false;
  
  // Analysis state
  final List<Map<String, dynamic>> _recentWindows = [];
  SleepPeriodCandidate? _currentSleepCandidate;
  final List<SleepSessionEstimated> _estimatedSessions = [];
  
  // Callbacks
  Function(SleepSessionEstimated)? onSleepSessionDetected;
  Function(Map<String, dynamic>)? onStatusUpdate;
  
  // Timer for periodic analysis
  Timer? _analysisTimer;
  
  /// Get current config
  SleepInferenceConfig get config => _config;
  
  /// Check if engine is running
  bool get isRunning => _isRunning;
  
  /// Get recent estimated sessions
  List<SleepSessionEstimated> get estimatedSessions => List.unmodifiable(_estimatedSessions);
  
  /// Update configuration
  void updateConfig(SleepInferenceConfig newConfig) {
    _config = newConfig;
  }
  
  /// Start the inference engine
  Future<bool> start() async {
    if (_isRunning) {
      debugPrint('[SleepInference] Already running');
      return true;
    }
    
    _isRunning = true;
    debugPrint('[SleepInference] Engine started');
    
    // Start periodic analysis
    _analysisTimer = Timer.periodic(
      Duration(minutes: _config.windowSizeMinutes),
      (_) => _analyzeSignals(),
    );
    
    return true;
  }
  
  /// Stop the inference engine
  Future<void> stop() async {
    _isRunning = false;
    _analysisTimer?.cancel();
    _analysisTimer = null;
    
    // Finalize any pending sleep session
    _finalizeSleepSession();
    
    debugPrint('[SleepInference] Engine stopped');
  }
  
  /// Process a new window analysis from the collector
  void processWindowAnalysis(Map<String, dynamic> analysis) {
    if (!_isRunning) return;
    
    _recentWindows.add(analysis);
    
    // Keep only recent windows (last 12 hours = 144 windows at 5 min intervals)
    while (_recentWindows.length > 144) {
      _recentWindows.removeAt(0);
    }
    
    // Calculate sleep score for this window
    final score = _calculateWindowScore(analysis);
    analysis['sleepScore'] = score;
    
    // Update status callback
    onStatusUpdate?.call({
      'currentScore': score,
      'windows': _recentWindows.length,
      'inSleepPeriod': _currentSleepCandidate?.startTime != null,
    });
  }
  
  /// Calculate sleep score for a window based on heuristics
  int _calculateWindowScore(Map<String, dynamic> analysis) {
    int score = 0;
    
    // Screen off (+30)
    if (analysis['wasScreenOff'] == true) {
      score += _config.screenOffScore;
    }
    
    // Charging (+20)
    if (analysis['wasCharging'] == true) {
      score += _config.chargingScore;
    }
    
    // Low motion (+30)
    if (analysis['isMostlyStill'] == true) {
      score += _config.lowMotionScore;
    }
    
    // High motion penalty (-30)
    final avgMotion = (analysis['avgMotion'] as num?)?.toDouble() ?? 0;
    if (avgMotion > 0.5) {
      score -= _config.motionPenalty;
    }
    
    // Unlock penalty (would need usage stats to detect)
    // This would be handled if phoneUsage signal is available
    
    return score.clamp(0, 100);
  }
  
  /// Analyze signals and detect sleep sessions
  void _analyzeSignals() {
    if (_recentWindows.isEmpty) return;
    
    // Get recent window scores
    final recentScores = _recentWindows
        .map((w) => w['sleepScore'] as int? ?? 0)
        .toList();
    
    // Check if we should start sleep
    if (_currentSleepCandidate?.startTime == null) {
      _checkSleepStart(recentScores);
    } else {
      _checkSleepEnd(recentScores);
    }
  }
  
  /// Check if sleep should start
  void _checkSleepStart(List<int> scores) {
    if (scores.isEmpty) return;
    
    // Get last N minutes of scores
    final recentScores = scores.length < _config.minScoreDurationMinutes
        ? scores
        : scores.sublist(scores.length - _config.minScoreDurationMinutes);
    
    // Check if enough consecutive high scores
    int consecutiveHigh = 0;
    for (int i = recentScores.length - 1; i >= 0; i--) {
      if (recentScores[i] >= _config.thresholdStart) {
        consecutiveHigh++;
      } else {
        break;
      }
    }
    
    // If enough consecutive high scores, start sleep
    if (consecutiveHigh >= _config.minScoreDurationMinutes ~/ _config.windowSizeMinutes) {
      final startTime = DateTime.now().subtract(
        Duration(minutes: consecutiveHigh * _config.windowSizeMinutes),
      );
      
      _currentSleepCandidate = SleepPeriodCandidate()
        ..startTime = startTime
        ..totalScore = recentScores.reduce((a, b) => a + b)
        ..scoreCount = recentScores.length;
      
      debugPrint('[SleepInference] Sleep started at $startTime');
    }
  }
  
  /// Check if sleep should end
  void _checkSleepEnd(List<int> scores) {
    if (_currentSleepCandidate == null || _currentSleepCandidate!.startTime == null) {
      return;
    }
    
    // Get last N scores
    final windowCount = _config.minScoreDurationMinutes ~/ _config.windowSizeMinutes;
    final recentScores = scores.length < windowCount
        ? scores
        : scores.sublist(scores.length - windowCount);
    
    // Check if enough low scores to end sleep
    int consecutiveLow = 0;
    for (int i = recentScores.length - 1; i >= 0; i--) {
      if (recentScores[i] <= _config.thresholdEnd) {
        consecutiveLow++;
      } else {
        break;
      }
    }
    
    if (consecutiveLow >= windowCount) {
      final endTime = DateTime.now().subtract(
        Duration(minutes: consecutiveLow * _config.windowSizeMinutes),
      );
      
      _currentSleepCandidate!.endTime = endTime;
      
      // Check if valid session
      if (_currentSleepCandidate!.isValid) {
        _finalizeSleepSession();
      } else {
        _currentSleepCandidate = null;
        debugPrint('[SleepInference] Invalid sleep candidate, discarded');
      }
    } else {
      // Update running score
      for (final score in recentScores) {
        _currentSleepCandidate!.totalScore += score;
        _currentSleepCandidate!.scoreCount++;
      }
    }
  }
  
  /// Finalize and store the detected sleep session
  void _finalizeSleepSession() {
    if (_currentSleepCandidate == null || !_currentSleepCandidate!.isValid) {
      _currentSleepCandidate = null;
      return;
    }
    
    final candidate = _currentSleepCandidate!;
    
    // Build signal summary
    final signalSummary = <String, dynamic>{
      'avgMotion': _calculateAvgMotion(candidate),
      'wasCharging': _checkWasCharging(candidate),
      'wasScreenOff': _checkWasScreenOff(candidate),
      'windowCount': candidate.scoreCount,
    };
    
    // Create sleep session
    final session = SleepSessionEstimated(
      startTime: candidate.startTime!.toUtc(),
      endTime: candidate.endTime!.toUtc(),
      durationMinutes: candidate.durationMinutes,
      source: SleepSource.estimatedPhoneSensors,
      confidenceScore: candidate.confidenceScore,
      signalSummary: signalSummary,
    );
    
    _estimatedSessions.add(session);
    _currentSleepCandidate = null;
    
    // Notify callback
    onSleepSessionDetected?.call(session);
    
    debugPrint('[SleepInference] Sleep session detected: ${session.durationFormatted}, confidence: ${session.confidenceScore}%');
  }
  
  /// Calculate average motion for a candidate
  double _calculateAvgMotion(SleepPeriodCandidate candidate) {
    double total = 0;
    int count = 0;
    
    for (final window in _recentWindows) {
      if (candidate.startTime != null) {
        // Only include windows during the candidate period
        // For simplicity, include all recent windows
        total += (window['avgMotion'] as num?)?.toDouble() ?? 0;
        count++;
      }
    }
    
    return count > 0 ? total / count : 0;
  }
  
  /// Check if was charging during sleep
  bool _checkWasCharging(SleepPeriodCandidate candidate) {
    for (final window in _recentWindows) {
      if (window['wasCharging'] == true) return true;
    }
    return false;
  }
  
  /// Check if was screen off during sleep
  bool _checkWasScreenOff(SleepPeriodCandidate candidate) {
    for (final window in _recentWindows) {
      if (window['wasScreenOff'] == true) return true;
    }
    return false;
  }
  
  /// Analyze historical data to estimate sleep for a time range
  Future<List<SleepSessionEstimated>> analyzeHistoricalRange(
    DateTime start,
    DateTime end,
  ) async {
    // This would load stored signal events and analyze them
    // For now, return empty list - would need to implement with storage
    return [];
  }
  
  /// Get current inference status
  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _isRunning,
      'recentWindows': _recentWindows.length,
      'inSleepPeriod': _currentSleepCandidate?.startTime != null,
      'currentCandidate': _currentSleepCandidate != null ? {
        'startTime': _currentSleepCandidate!.startTime?.toIso8601String(),
        'avgScore': _currentSleepCandidate!.averageScore,
        'durationMinutes': _currentSleepCandidate!.durationMinutes,
      } : null,
      'estimatedSessionsCount': _estimatedSessions.length,
    };
  }
  
  /// Clear all stored sessions (for testing or reset)
  void clearSessions() {
    _estimatedSessions.clear();
    _currentSleepCandidate = null;
    _recentWindows.clear();
  }
  
  /// Dispose resources
  void dispose() {
    stop();
    _instance = null;
  }
}
