// Sleep Widget - Optimized Premium Design
// Displays last night's sleep summary with beautiful gradient and clear layout
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/sleep_record.dart';
import '../../../services/sleep_service.dart';
import '../../../theme/app_icons.dart';
import '../../sleep/sleep_tracking_screen.dart';

class SleepWidget extends StatefulWidget {
  const SleepWidget({super.key});

  @override
  State<SleepWidget> createState() => _SleepWidgetState();
}

class _SleepWidgetState extends State<SleepWidget> {
  SleepRecord? _lastNightSleep;
  double _avgDuration = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final lastNight = await SleepService.getLastNightSleepRecord();
      final avgDuration = await SleepService.getAverageSleepDuration(days: 7);

      if (mounted) {
        setState(() {
          _lastNightSleep = lastNight;
          _avgDuration = avgDuration;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const SleepTrackingScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1), // Indigo
              const Color(0xFF8B5CF6), // Purple
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child:
            _isLoading
                ? _buildLoading()
                : _lastNightSleep != null
                ? _buildWithData()
                : _buildNoData(),
      ),
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 70,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      ),
    );
  }

  Widget _buildNoData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with glow effect
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(AppIcons.sleep, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 12),
        // Title
        const Text(
          'Giấc ngủ',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        // Subtitle with indicator
        Row(
          children: [
            Expanded(
              child: Text(
                'Chạm để ghi nhận',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_right,
              color: Colors.white.withValues(alpha: 0.6),
              size: 14,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWithData() {
    final sleep = _lastNightSleep!;
    final scoreColor = _getScoreColor(sleep.sleepScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with icon and score
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(AppIcons.sleep, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Đêm qua',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${sleep.sleepScore}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Duration - Large display
        Text(
          sleep.durationFormatted,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),

        // Quality label
        Row(
          children: [
            if (sleep.quality != null) ...[
              Text(sleep.quality!.emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
            ],
            Text(
              sleep.sleepScoreLabel,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),

        // Average stats if available
        if (_avgDuration > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.chart_bar,
                  color: Colors.white.withValues(alpha: 0.65),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Avg: ${_avgDuration.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.greenAccent.shade200;
    if (score >= 60) return Colors.lightGreenAccent.shade200;
    if (score >= 40) return Colors.orangeAccent.shade100;
    return Colors.redAccent.shade100;
  }
}
