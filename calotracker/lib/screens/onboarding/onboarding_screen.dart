// Onboarding Screen - Revamped Modern Soft Minimalist Design
// First-time user setup with profile and goal selection
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../theme/colors.dart';

import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

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

  // Focus nodes for input styling
  final _nameFocus = FocusNode();
  final _heightFocus = FocusNode();
  final _weightFocus = FocusNode();

  // Animation controllers
  late AnimationController _cardScaleController;
  late Animation<double> _cardScaleAnimation;

  @override
  void initState() {
    super.initState();
    _cardScaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _cardScaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _cardScaleController, curve: Curves.easeInOut),
    );

    // Listen for focus changes to rebuild UI
    _nameFocus.addListener(() => setState(() {}));
    _heightFocus.addListener(() => setState(() {}));
    _weightFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _nameFocus.dispose();
    _heightFocus.dispose();
    _weightFocus.dispose();
    _cardScaleController.dispose();
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
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _updateGoal(String goal) {
    setState(() {
      _selectedGoal = goal;
      _dailyTarget = UserProfile.calculateDailyTarget(_bmr, goal);
    });
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🚀 Starting onboarding completion...');

      final profile = UserProfile.create(
        name: _nameController.text.trim(),
        height: double.tryParse(_heightController.text) ?? 0,
        weight: double.tryParse(_weightController.text) ?? 0,
        goal: _selectedGoal,
        country: _selectedCountry,
        language: 'vi',
      );

      debugPrint('✅ Profile created: ${profile.name}');

      // Save to SharedPreferences
      final profileSaved = await StorageService.saveUserProfile(profile);
      debugPrint('✅ Profile saved to storage: $profileSaved');

      final onboardingMarked = await StorageService.setOnboardingComplete(true);
      debugPrint('✅ Onboarding marked complete: $onboardingMarked');

      // Verify onboarding completion was saved
      final isComplete = StorageService.isOnboardingComplete();
      debugPrint('✅ Onboarding verification: $isComplete');

      if (!isComplete) {
        throw Exception('Failed to mark onboarding as complete');
      }

      // Save to database (non-critical, don't block on failure)
      try {
        await DatabaseService.saveUser(profile);
        debugPrint('✅ Profile saved to database');
      } catch (e) {
        debugPrint('⚠️ Warning: Failed to save user to database: $e');
      }

      debugPrint('🎉 Onboarding completed successfully!');

      // Navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Onboarding error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _completeOnboarding,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlue.withValues(alpha: 0.03),
              Colors.white,
              const Color(0xFFF8FAFC),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress and back button
              _buildHeader(),

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
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Back button (visible only on step 2)
          AnimatedOpacity(
            opacity: _currentPage > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _currentPage > 0 ? _goToPreviousPage : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.chevron_left,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Progress bar
          Expanded(child: _buildProgressBar()),

          const SizedBox(width: 56), // Balance the back button space
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * ((_currentPage + 1) / 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue,
                      AppColors.primaryBlue.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Welcome Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.15),
                    AppColors.primaryBlue.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                CupertinoIcons.person_crop_circle_badge_plus,
                size: 36,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Chào mừng đến\nCaloTracker 👋',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hãy thiết lập hồ sơ của bạn để bắt đầu hành trình sức khỏe',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // Country selector
            _buildSectionLabel('Quốc gia', CupertinoIcons.globe),
            const SizedBox(height: 12),
            _buildCountrySelector(),
            const SizedBox(height: 28),

            // Name field
            _buildSectionLabel('Tên của bạn', CupertinoIcons.person),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              focusNode: _nameFocus,
              hintText: 'Nhập tên của bạn',
              prefixIcon: CupertinoIcons.person_fill,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Height field
            _buildSectionLabel('Chiều cao', CupertinoIcons.resize_v),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _heightController,
              focusNode: _heightFocus,
              hintText: 'Nhập chiều cao',
              prefixIcon: CupertinoIcons.resize_v,
              suffixText: 'cm',
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
            const SizedBox(height: 28),

            // Weight field
            _buildSectionLabel('Cân nặng', CupertinoIcons.gauge),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _weightController,
              focusNode: _weightFocus,
              hintText: 'Nhập cân nặng',
              prefixIcon: CupertinoIcons.gauge,
              suffixText: 'kg',
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
            _buildPrimaryButton(
              onPressed: _goToNextPage,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Tiếp theo',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.arrow_right, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    final bool isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isFocused
                ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: isFocused ? Colors.white : Colors.grey.shade50,
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              prefixIcon,
              size: 22,
              color: isFocused ? AppColors.primaryBlue : Colors.grey[400],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildCountrySelector() {
    final countries = StorageService.getSupportedCountries();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountry,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          borderRadius: BorderRadius.circular(16),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: AppColors.primaryBlue,
            ),
          ),
          items:
              countries.map((country) {
                return DropdownMenuItem<String>(
                  value: country['code'],
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            country['flag']!,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        country['name']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Goal Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF9800).withValues(alpha: 0.15),
                  const Color(0xFFFF5722).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.flame_fill,
              size: 36,
              color: Color(0xFFFF5722),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Mục tiêu của bạn 🎯',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chọn mục tiêu phù hợp để chúng tôi tính toán lượng calo tối ưu',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // BMR Highlight Box
          _buildBMRHighlightBox(),
          const SizedBox(height: 32),

          // Goal cards
          _buildGoalCard(
            goal: 'lose',
            icon: CupertinoIcons.arrow_down_circle_fill,
            iconColor: const Color(0xFFEF5350),
            iconBgColor: const Color(0xFFFFEBEE),
            title: 'Giảm cân',
            subtitle: 'Giảm 20% lượng calo',
            calories: (_bmr * 0.8).toInt(),
          ),
          const SizedBox(height: 16),
          _buildGoalCard(
            goal: 'maintain',
            icon: CupertinoIcons.equal_circle_fill,
            iconColor: AppColors.primaryBlue,
            iconBgColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            title: 'Duy trì',
            subtitle: 'Giữ nguyên cân nặng',
            calories: _bmr.toInt(),
          ),
          const SizedBox(height: 16),
          _buildGoalCard(
            goal: 'gain',
            icon: CupertinoIcons.arrow_up_circle_fill,
            iconColor: const Color(0xFF66BB6A),
            iconBgColor: const Color(0xFFE8F5E9),
            title: 'Tăng cân',
            subtitle: 'Tăng 20% lượng calo',
            calories: (_bmr * 1.2).toInt(),
          ),
          const SizedBox(height: 32),

          // Daily target display
          _buildDailyTargetBox(),
          const SizedBox(height: 36),

          // Start button
          _buildPrimaryButton(
            onPressed: _isLoading ? null : _completeOnboarding,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Bắt đầu hành trình',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.rocket_fill, size: 20),
                      ],
                    ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBMRHighlightBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.08),
            AppColors.primaryBlue.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              CupertinoIcons.flame_fill,
              color: AppColors.primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMR của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_bmr.toInt()}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'kcal/ngày',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required String goal,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required int calories,
  }) {
    final isSelected = _selectedGoal == goal;

    return GestureDetector(
      onTap: () => _updateGoal(goal),
      onTapDown: (_) => _cardScaleController.forward(),
      onTapUp: (_) => _cardScaleController.reverse(),
      onTapCancel: () => _cardScaleController.reverse(),
      child: AnimatedBuilder(
        animation: _cardScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _selectedGoal == goal ? 1.0 : _cardScaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              width: 2,
            ),
            gradient:
                isSelected
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryBlue.withValues(alpha: 0.08),
                        Colors.white,
                      ],
                    )
                    : null,
            boxShadow: [
              BoxShadow(
                color:
                    isSelected
                        ? AppColors.primaryBlue.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                blurRadius: isSelected ? 20 : 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? AppColors.primaryBlue : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // Calories display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$calories',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected ? AppColors.primaryBlue : Colors.black87,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey[100],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? const Icon(
                          CupertinoIcons.checkmark,
                          color: Colors.white,
                          size: 16,
                        )
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTargetBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.scope,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Mục tiêu hàng ngày',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_dailyTarget.toInt()}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primaryBlue.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: child,
      ),
    );
  }
}
