import 'package:flutter/material.dart';
import 'marketing_bridge.dart';

/// Auto-detect crisis: 3× craving > 8 + mood = 1 within 2 hours → trigger 3 AM SOS
class CrisisDetectionService {
  static final CrisisDetectionService _instance = CrisisDetectionService._();
  factory CrisisDetectionService() => _instance;
  CrisisDetectionService._();

  final List<_CheckinSnapshot> _recent = [];
  static const _windowDuration = Duration(hours: 2);
  static const _cravingThreshold = 8;
  static const _requiredHighCravings = 3;

  VoidCallback? onCrisisDetected;

  void recordCheckin({required int mood, required int cravingLevel}) {
    _recent.add(_CheckinSnapshot(
      mood: mood,
      cravingLevel: cravingLevel,
      timestamp: DateTime.now(),
    ));
    _pruneOld();
    if (_isCrisis()) {
      MarketingBridge().onCrisisDetected();
      onCrisisDetected?.call();
    }
  }

  bool _isCrisis() {
    final highCravings =
        _recent.where((s) => s.cravingLevel > _cravingThreshold).length;
    final hasCriticalMood = _recent.any((s) => s.mood == 1);
    return highCravings >= _requiredHighCravings && hasCriticalMood;
  }

  void _pruneOld() {
    final cutoff = DateTime.now().subtract(_windowDuration);
    _recent.removeWhere((s) => s.timestamp.isBefore(cutoff));
  }
}

class _CheckinSnapshot {
  final int mood;
  final int cravingLevel;
  final DateTime timestamp;

  _CheckinSnapshot({
    required this.mood,
    required this.cravingLevel,
    required this.timestamp,
  });
}
