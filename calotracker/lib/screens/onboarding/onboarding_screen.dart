// Onboarding Screen
// First-time user setup with profile and goal selection
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1 fields
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Step 2 selection
  String _selectedGoal = 'maintain';

  // Calculated values
  double _bmr = 0;
  double _dailyTarget = 0;

  // Selected country
  String _selectedCountry = 'VN';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage == 0) {
      if (!_formKey.currentState!.validate()) return;

      // Calculate BMR
      final weight = double.tryParse(_weightController.text) ?? 0;
      final height = double.tryParse(_heightController.text) ?? 0;
      _bmr = UserProfile.calculateBMR(weight, height);
      _dailyTarget = UserProfile.calculateDailyTarget(_bmr, _selectedGoal);
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _updateGoal(String goal) {
    setState(() {
      _selectedGoal = goal;
      _dailyTarget = UserProfile.calculateDailyTarget(_bmr, goal);
    });
  }

  Future<void> _completeOnboarding() async {
    final profile = UserProfile.create(
      name: _nameController.text.trim(),
      height: double.tryParse(_heightController.text) ?? 0,
      weight: double.tryParse(_weightController.text) ?? 0,
      goal: _selectedGoal,
      country: _selectedCountry,
      language: 'vi',
    );

    // Save to SharedPreferences
    await StorageService.saveUserProfile(profile);
    await StorageService.setOnboardingComplete(true);

    // Save to database
    await DatabaseService.saveUser(profile);

    // Navigate to home
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  _buildProgressDot(0),
                  Expanded(child: _buildProgressLine(0)),
                  _buildProgressDot(1),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [_buildStep1(), _buildStep2()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDot(int index) {
    final isActive = _currentPage >= index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primaryBlue : AppColors.lightDivider,
      ),
    );
  }

  Widget _buildProgressLine(int index) {
    final isActive = _currentPage > index;
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryBlue : AppColors.lightDivider,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Chào mừng đến\nCaloTracker 👋',
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thiết lập hồ sơ của bạn để bắt đầu',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),

            // Country selector
            Text('Quốc gia', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            _buildCountrySelector(),
            const SizedBox(height: 24),

            // Name field
            Text('Tên của bạn', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Nhập tên của bạn',
                prefixIcon: Icon(CupertinoIcons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Height field
            Text('Chiều cao', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(
                hintText: 'Nhập chiều cao',
                prefixIcon: Icon(CupertinoIcons.resize_v),
                suffixText: 'cm',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập chiều cao';
                }
                final height = double.tryParse(value);
                if (height == null || height < 100 || height > 250) {
                  return 'Chiều cao không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Weight field
            Text('Cân nặng', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                hintText: 'Nhập cân nặng',
                prefixIcon: Icon(CupertinoIcons.gauge),
                suffixText: 'kg',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập cân nặng';
                }
                final weight = double.tryParse(value);
                if (weight == null || weight < 30 || weight > 300) {
                  return 'Cân nặng không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 48),

            // Next button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _goToNextPage,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Tiếp theo'),
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.arrow_right, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    final countries = StorageService.getSupportedCountries();

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
            setState(() => _selectedCountry = value!);
          },
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          IconButton(
            onPressed: _goToPreviousPage,
            icon: const Icon(CupertinoIcons.arrow_left),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 16),

          // Title
          Text('Mục tiêu của bạn 🎯', style: AppTextStyles.heading1),
          const SizedBox(height: 8),
          Text(
            'Chọn mục tiêu phù hợp với bạn',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // BMR display
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.flame,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BMR của bạn',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${_bmr.toInt()} kcal/ngày',
                      style: AppTextStyles.heading3,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Goal cards
          _buildGoalCard(
            goal: 'lose',
            icon: '🔴',
            title: 'Giảm cân',
            subtitle: 'Giảm 20% lượng calo',
            calories: (_bmr * 0.8).toInt(),
          ),
          const SizedBox(height: 16),
          _buildGoalCard(
            goal: 'maintain',
            icon: '🔵',
            title: 'Duy trì',
            subtitle: 'Giữ nguyên cân nặng',
            calories: _bmr.toInt(),
          ),
          const SizedBox(height: 16),
          _buildGoalCard(
            goal: 'gain',
            icon: '🟢',
            title: 'Tăng cân',
            subtitle: 'Tăng 20% lượng calo',
            calories: (_bmr * 1.2).toInt(),
          ),
          const SizedBox(height: 32),

          // Daily target display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mục tiêu hàng ngày', style: AppTextStyles.labelLarge),
                Text(
                  '${_dailyTarget.toInt()} kcal',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Start button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bắt đầu'),
                  SizedBox(width: 8),
                  Icon(CupertinoIcons.rocket, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required String goal,
    required String icon,
    required String title,
    required String subtitle,
    required int calories,
  }) {
    final isSelected = _selectedGoal == goal;

    return GestureDetector(
      onTap: () => _updateGoal(goal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 2,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: isSelected ? AppColors.primaryBlue : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$calories',
                  style: AppTextStyles.heading3.copyWith(
                    color: isSelected ? AppColors.primaryBlue : null,
                  ),
                ),
                Text(
                  'kcal/ngày',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color:
                  isSelected ? AppColors.primaryBlue : AppColors.lightDivider,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
