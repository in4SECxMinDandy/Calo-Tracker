// Water Intake Widget - Simple & Stable Layout
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/water_record.dart';
import '../../../services/water_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/app_icons.dart';

class WaterIntakeWidget extends StatefulWidget {
  final VoidCallback? onWaterAdded;

  const WaterIntakeWidget({super.key, this.onWaterAdded});

  @override
  State<WaterIntakeWidget> createState() => _WaterIntakeWidgetState();
}

class _WaterIntakeWidgetState extends State<WaterIntakeWidget> {
  DailyWaterSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final summary = await WaterService.getTodaySummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWater(int amountMl) async {
    await WaterService.addWaterIntake(amountMl);
    await _loadData();
    widget.onWaterAdded?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+${amountMl}ml 💧'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2196F3),
        ),
      );
    }
  }

  void _showCustomDialog() {
    int amount = 200;
    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setState) => CupertinoAlertDialog(
                  title: const Text('Thêm nước'),
                  content: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        '${amount}ml',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoSlider(
                        value: amount.toDouble(),
                        min: 50,
                        max: 1000,
                        divisions: 19,
                        onChanged: (v) => setState(() => amount = v.round()),
                      ),
                    ],
                  ),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Hủy'),
                    ),
                    CupertinoDialogAction(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _addWater(amount);
                      },
                      child: const Text('Thêm'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary =
        _summary ?? DailyWaterSummary.empty(DateTime.now().toString());
    final progress = (summary.progressPercent / 100).clamp(0.0, 1.0);
    final progressColor = _getProgressColor(summary.progressPercent);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child:
          _isLoading
              ? const SizedBox(
                height: 160,
                child: Center(child: CupertinoActivityIndicator()),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        AppIcons.water,
                        color: const Color(0xFF2196F3),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Nước',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: progressColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${summary.progressPercent.toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Stats
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${summary.totalAmount}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '/${summary.targetAmount}ml',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor:
                          isDark ? Colors.white12 : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2196F3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Remaining
                  Text(
                    summary.remainingAmount > 0
                        ? 'Còn ${summary.remainingAmount}ml'
                        : '✅ Hoàn thành!',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          summary.remainingAmount > 0
                              ? (isDark ? Colors.white54 : Colors.black45)
                              : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button Grid 2x2
                  Row(
                    children: [
                      Expanded(child: _buildBtn(100, isDark)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildBtn(250, isDark)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildBtn(500, isDark)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildMoreBtn(isDark)),
                    ],
                  ),
                ],
              ),
    );
  }

  Widget _buildBtn(int amount, bool isDark) {
    return GestureDetector(
      onTap: () => _addWater(amount),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color:
              isDark
                  ? const Color(0xFF2196F3).withValues(alpha: 0.15)
                  : const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          '+$amount',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1976D2),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreBtn(bool isDark) {
    return GestureDetector(
      onTap: _showCustomDialog,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const Icon(
          CupertinoIcons.ellipsis,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 30) return Colors.red;
    if (progress < 60) return Colors.orange;
    if (progress < 100) return const Color(0xFF2196F3);
    return Colors.green;
  }
}
