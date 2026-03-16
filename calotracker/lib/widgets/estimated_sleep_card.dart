// Estimated Sleep Session Card
// Displays an estimated sleep session from passive tracking
import 'package:flutter/material.dart';
import '../../models/sleep_session_estimated.dart';

class EstimatedSleepCard extends StatelessWidget {
  final SleepSessionEstimated session;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  
  const EstimatedSleepCard({
    super.key,
    required this.session,
    this.onTap,
    this.onEdit,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);
    
    // Get confidence color
    Color confidenceColor;
    if (session.confidenceScore >= 85) {
      confidenceColor = Colors.green;
    } else if (session.confidenceScore >= 60) {
      confidenceColor = Colors.orange;
    } else {
      confidenceColor = Colors.red;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Date and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.dateFormatted,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${session.startTimeFormatted} → ${session.endTimeFormatted}',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Confidence badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: confidenceColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: confidenceColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${session.confidenceScore}%',
                          style: TextStyle(
                            color: confidenceColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Stats row
              Row(
                children: [
                  // Duration
                  _StatItem(
                    icon: Icons.access_time,
                    label: 'Thời lượng',
                    value: session.durationFormatted,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Source
                  _StatItem(
                    icon: Icons.phone_android,
                    label: 'Nguồn',
                    value: session.sourceLabel,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  
                  const Spacer(),
                  
                  // Label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session.label,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Edit button for manual adjustments
              if (onEdit != null && session.source == SleepSource.estimatedPhoneSensors) ...[
                const SizedBox(height: 12),
                Divider(color: textSecondary.withValues(alpha: 0.2)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onEdit,
                      child: Text(
                        'Chỉnh sửa thủ công',
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
