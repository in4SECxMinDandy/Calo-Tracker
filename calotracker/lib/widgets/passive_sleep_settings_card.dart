// Passive Sleep Settings Card
// UI component for enabling/configuring passive sleep tracking
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/sleep/passive_sleep_service.dart';
import '../../services/storage_service.dart';

class PassiveSleepSettingsCard extends StatefulWidget {
  final VoidCallback? onToggle;
  final VoidCallback? onAnalyzeRequested;
  
  const PassiveSleepSettingsCard({
    super.key,
    this.onToggle,
    this.onAnalyzeRequested,
  });
  
  @override
  State<PassiveSleepSettingsCard> createState() => _PassiveSleepSettingsCardState();
}

class _PassiveSleepSettingsCardState extends State<PassiveSleepSettingsCard> {
  bool _isEnabled = false;
  bool _isAnalyzing = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final enabled = StorageService.isPassiveSleepEnabled();
    setState(() {
      _isEnabled = enabled;
    });
  }
  
  Future<void> _toggleEnabled(bool value) async {
    await StorageService.setPassiveSleepEnabled(value);
    await PassiveSleepService.instance.setEnabled(value);
    
    setState(() {
      _isEnabled = value;
    });
    
    widget.onToggle?.call();
  }
  
  Future<void> _analyzeLastNight() async {
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final session = await PassiveSleepService.instance.analyzeLastNight();
      
      if (mounted) {
        if (session != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã phát hiện: ${session.durationFormatted}, độ tin cậy: ${session.confidenceScore}%'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Không tìm thấy dữ liệu giấc ngủ đêm qua'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
    
    widget.onAnalyzeRequested?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEnabled 
              ? Colors.purple.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.nightlight_round,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theo dõi giấc ngủ thụ động',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ước lượng giấc ngủ từ cảm biến điện thoại',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _isEnabled,
                  onChanged: _toggleEnabled,
                  activeTrackColor: Colors.purple,
                ),
              ],
            ),
          ),
          
          // Disclaimer
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đây là ước lượng, không phải thiết bị y tế. Kết quả có thể không chính xác.',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Analyze button
          if (_isEnabled)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeLastNight,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 18),
                  label: Text(
                    _isAnalyzing ? 'Đang phân tích...' : 'Phân tích đêm qua',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(color: Colors.purple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
