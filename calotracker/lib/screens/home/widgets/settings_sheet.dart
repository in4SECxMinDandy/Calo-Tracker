// Settings Sheet
// Bottom sheet for app settings (language, country, theme, etc.)
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../main.dart';
import '../../../services/storage_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';

class SettingsSheet extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsSheet({super.key, this.onSettingsChanged});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  String _selectedCountry = 'VN';
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _selectedCountry = StorageService.getCountry();
      _notificationsEnabled = StorageService.isNotificationsEnabled();
      _darkModeEnabled = StorageService.isDarkMode();
    });
  }

  Future<void> _updateCountry(String country) async {
    await StorageService.setCountry(country);
    setState(() => _selectedCountry = country);
    widget.onSettingsChanged?.call();
  }

  Future<void> _toggleNotifications(bool enabled) async {
    await StorageService.setNotificationsEnabled(enabled);
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _toggleDarkMode(bool enabled) async {
    await StorageService.setDarkMode(enabled);
    setState(() => _darkModeEnabled = enabled);
    widget.onSettingsChanged?.call();

    // Rebuild the entire app with new theme
    if (mounted) {
      CaloTrackerApp.rebuild(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final countries = StorageService.getSupportedCountries();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cài đặt', style: AppTextStyles.heading2),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Settings list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country
                    Text('Quốc gia', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 12),
                    _buildCountrySelector(countries),
                    const SizedBox(height: 24),

                    // Dark Mode
                    _buildSettingRow(
                      icon: CupertinoIcons.moon_fill,
                      title: 'Chế độ tối',
                      subtitle: 'Giao diện Dark Mode',
                      trailing: CupertinoSwitch(
                        value: _darkModeEnabled,
                        onChanged: _toggleDarkMode,
                        activeTrackColor: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notifications
                    _buildSettingRow(
                      icon: CupertinoIcons.bell,
                      title: 'Thông báo',
                      subtitle: 'Nhận nhắc nhở tập gym',
                      trailing: CupertinoSwitch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeTrackColor: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Version info
                    _buildSettingRow(
                      icon: CupertinoIcons.info,
                      title: 'Phiên bản',
                      subtitle: 'CaloTracker v1.0.0',
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySelector(List<Map<String, String>> countries) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountry,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          items:
              countries.map((country) {
                return DropdownMenuItem<String>(
                  value: country['code'],
                  child: Row(
                    children: [
                      Text(
                        country['flag']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(country['name']!),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) _updateCountry(value);
          },
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
