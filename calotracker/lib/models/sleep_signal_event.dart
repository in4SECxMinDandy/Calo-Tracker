// Sleep Signal Event Model
// Represents individual sensor events collected during passive sleep tracking

import 'package:uuid/uuid.dart';

/// Types of sleep signals that can be collected
enum SleepSignalType {
  accelerometer,      // Motion detected via accelerometer
  screenState,        // Screen on/off events
  chargingState,      // Power connected/disconnected
  phoneUsage,         // App usage / interaction
  doNotDisturb,       // DND mode status (if available)
  batteryLevel,       // Battery percentage changes
}

/// Represents the state change value for each signal type
enum SignalValue {
  // Screen states
  screenOn,
  screenOff,
  
  // Charging states
  charging,
  unplugged,
  
  // Activity states
  active,       // User actively using phone
  inactive,     // No interaction for period
  
  // DND states
  dndOn,
  dndOff,
}

class SleepSignalEvent {
  final String id;
  final SleepSignalType type;
  final SignalValue value;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // Additional data like motion magnitude
  
  SleepSignalEvent({
    String? id,
    required this.type,
    required this.value,
    DateTime? timestamp,
    this.metadata,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now().toUtc();
  
  /// Get human-readable label for the signal type
  String get typeLabel {
    switch (type) {
      case SleepSignalType.accelerometer:
        return 'Gia tốc kế';
      case SleepSignalType.screenState:
        return 'Màn hình';
      case SleepSignalType.chargingState:
        return 'Sạc pin';
      case SleepSignalType.phoneUsage:
        return 'Sử dụng điện thoại';
      case SleepSignalType.doNotDisturb:
        return 'Không làm phiền';
      case SleepSignalType.batteryLevel:
        return 'Pin';
    }
  }
  
  /// Get human-readable label for the signal value
  String get valueLabel {
    switch (value) {
      case SignalValue.screenOn:
        return 'Bật';
      case SignalValue.screenOff:
        return 'Tắt';
      case SignalValue.charging:
        return 'Đang sạc';
      case SignalValue.unplugged:
        return 'Rút sạc';
      case SignalValue.active:
        return 'Hoạt động';
      case SignalValue.inactive:
        return 'Không hoạt động';
      case SignalValue.dndOn:
        return 'Bật';
      case SignalValue.dndOff:
        return 'Tắt';
    }
  }
  
  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'value': value.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'metadata': metadata != null ? _encodeMetadata(metadata!) : null,
    };
  }
  
  /// Create from database Map
  factory SleepSignalEvent.fromMap(Map<String, dynamic> map) {
    return SleepSignalEvent(
      id: map['id'] as String,
      type: SleepSignalType.values.firstWhere((e) => e.name == map['type']),
      value: SignalValue.values.firstWhere((e) => e.name == map['value']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      metadata: map['metadata'] != null ? _decodeMetadata(map['metadata'] as String) : null,
    );
  }
  
  /// Encode metadata to JSON string
  static String _encodeMetadata(Map<String, dynamic> metadata) {
    return _jsonEncode(metadata);
  }
  
  /// Decode metadata from JSON string
  static Map<String, dynamic> _decodeMetadata(String encoded) {
    return _jsonDecode(encoded);
  }
  
  // Simple JSON encoder/decoder to avoid dart:convert import issues
  static String _jsonEncode(Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    var first = true;
    map.forEach((key, value) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"$key":');
      if (value is String) {
        buffer.write('"$value"');
      } else if (value is num) {
        buffer.write(value.toString());
      } else if (value is bool) {
        buffer.write(value.toString());
      } else {
        buffer.write('"$value"');
      }
    });
    buffer.write('}');
    return buffer.toString();
  }
  
  static Map<String, dynamic> _jsonDecode(String encoded) {
    // Simple parser for our simple format
    final result = <String, dynamic>{};
    if (encoded.length <= 2) return result;
    
    final content = encoded.substring(1, encoded.length - 1);
    final pairs = _splitSimpleJson(content);
    
    for (final pair in pairs) {
      final colonIdx = pair.indexOf(':');
      if (colonIdx == -1) continue;
      
      var key = pair.substring(0, colonIdx).trim();
      var value = pair.substring(colonIdx + 1).trim();
      
      // Remove quotes
      if (key.startsWith('"') && key.endsWith('"')) {
        key = key.substring(1, key.length - 1);
      }
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      } else if (value == 'true') {
        return {key: true};
      } else if (value == 'false') {
        return {key: false};
      } else if (value.contains('.')) {
        return {key: double.tryParse(value) ?? 0.0};
      } else {
        final intVal = int.tryParse(value);
        return {key: intVal ?? value};
      }
      result[key] = value;
    }
    return result;
  }
  
  static List<String> _splitSimpleJson(String content) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuote = false;
    var depth = 0;
    
    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '"') {
        inQuote = !inQuote;
        current.write(char);
      } else if (!inQuote) {
        if (char == '{' || char == '[') depth++;
        if (char == '}' || char == ']') depth--;
        if (char == ',' && depth == 0) {
          result.add(current.toString().trim());
          current = StringBuffer();
        } else {
          current.write(char);
        }
      } else {
        current.write(char);
      }
    }
    if (current.isNotEmpty) {
      result.add(current.toString().trim());
    }
    return result;
  }
  
  /// Convert to JSON-friendly map for export
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'value': value.name,
    'timestamp': timestamp.toIso8601String(),
    'typeLabel': typeLabel,
    'valueLabel': valueLabel,
    if (metadata != null) 'metadata': metadata,
  };
}
