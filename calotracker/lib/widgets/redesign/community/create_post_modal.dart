// Create Post Modal - Bottom Sheet for Creating Community Posts
// Synced with React CreatePostModal component
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';

class CreatePostData {
  final String content;
  final String? mealName;
  final MacroInput? macros;
  final String? location;
  final String? imagePath;

  const CreatePostData({
    required this.content,
    this.mealName,
    this.macros,
    this.location,
    this.imagePath,
  });
}

class MacroInput {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const MacroInput({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class CreatePostModal extends StatefulWidget {
  final Function(CreatePostData) onPost;
  final String userName;
  final String userAvatar;

  const CreatePostModal({
    super.key,
    required this.onPost,
    required this.userName,
    required this.userAvatar,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(CreatePostData) onPost,
    required String userName,
    required String userAvatar,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostModal(
        onPost: onPost,
        userName: userName,
        userAvatar: userAvatar,
      ),
    );
  }

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal>
    with SingleTickerProviderStateMixin {
  final _contentController = TextEditingController();
  final _mealNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _locationController = TextEditingController();

  bool _showMealForm = false;
  bool _showLocation = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _mealNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _locationController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handlePost() {
    if (_contentController.text.trim().isEmpty) return;

    final macros = _caloriesController.text.isNotEmpty
        ? MacroInput(
            calories: int.tryParse(_caloriesController.text) ?? 0,
            protein: int.tryParse(_proteinController.text) ?? 0,
            carbs: int.tryParse(_carbsController.text) ?? 0,
            fat: int.tryParse(_fatController.text) ?? 0,
          )
        : null;

    final postData = CreatePostData(
      content: _contentController.text,
      mealName: _mealNameController.text.isNotEmpty
          ? _mealNameController.text
          : null,
      macros: macros,
      location: _locationController.text.isNotEmpty
          ? _locationController.text
          : null,
    );

    widget.onPost(postData);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, isDark),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfo(context, isDark),
                    _buildTextInput(context, isDark),
                    if (_showMealForm) _buildMealForm(context, isDark),
                    if (_showLocation) _buildLocationInput(context, isDark),
                  ],
                ),
              ),
            ),
            _buildActionBar(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final canPost = _contentController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ),

          // Title
          Text(
            'Tạo bài viết',
            style: AppTextStyles.heading3.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),

          // Post button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canPost ? _handlePost : null,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: canPost
                      ? AppColors.successGreen
                      : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: canPost
                      ? [
                          BoxShadow(
                            color:
                                AppColors.successGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Đăng',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: canPost
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(widget.userAvatar),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (_locationController.text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 12,
                        color: isDark
                            ? AppColors.accentMint
                            : AppColors.successGreen,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _locationController.text,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.accentMint
                                : AppColors.successGreen,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        minLines: 5,
        decoration: InputDecoration(
          hintText: 'Chia sẻ hành trình sức khỏe của bạn...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextSecondary,
          ),
          border: InputBorder.none,
        ),
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 15,
          height: 1.6,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildMealForm(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.successGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.square_favorites_alt,
                  size: 16,
                  color: isDark
                      ? AppColors.accentMint
                      : AppColors.successGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thông tin bữa ăn',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.accentMint
                        : AppColors.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMealInput(
              controller: _mealNameController,
              hint: 'Tên món ăn',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMealInput(
                    controller: _caloriesController,
                    hint: '🔥 Calo (kcal)',
                    isDark: isDark,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMealInput(
                    controller: _proteinController,
                    hint: '💪 Protein (g)',
                    isDark: isDark,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMealInput(
                    controller: _carbsController,
                    hint: '🍞 Carbs (g)',
                    isDark: isDark,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMealInput(
                    controller: _fatController,
                    hint: '🥑 Fat (g)',
                    isDark: isDark,
                    isNumber: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealInput({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.labelMedium.copyWith(
          fontSize: 13,
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextSecondary,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.successGreen.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 13,
        color: isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildLocationInput(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _locationController,
        decoration: InputDecoration(
          hintText: 'Nhập vị trí...',
          hintStyle: AppTextStyles.labelMedium.copyWith(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextSecondary,
          ),
          filled: true,
          fillColor: isDark ? AppColors.darkMuted : AppColors.lightMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.successGreen.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 13,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildActionButton(
            icon: CupertinoIcons.camera,
            label: 'Camera',
            color: AppColors.successGreen,
            isDark: isDark,
            onTap: () {
              // TODO: Implement camera
            },
          ),
          _buildActionButton(
            icon: CupertinoIcons.photo,
            label: 'Ảnh',
            color: AppColors.primaryBlue,
            isDark: isDark,
            onTap: () {
              // TODO: Implement image picker
            },
          ),
          _buildActionButton(
            icon: CupertinoIcons.square_favorites_alt,
            label: 'Bữa ăn',
            color: AppColors.warningOrange,
            isDark: isDark,
            isActive: _showMealForm,
            onTap: () {
              setState(() {
                _showMealForm = !_showMealForm;
              });
            },
          ),
          _buildActionButton(
            icon: CupertinoIcons.location,
            label: 'Vị trí',
            color: AppColors.errorRed,
            isDark: isDark,
            isActive: _showLocation,
            onTap: () {
              setState(() {
                _showLocation = !_showLocation;
              });
            },
          ),
          _buildActionButton(
            icon: CupertinoIcons.smiley,
            label: 'Emoji',
            color: AppColors.primaryIndigo,
            isDark: isDark,
            onTap: () {
              // TODO: Implement emoji picker
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? AppColors.darkMuted : AppColors.lightMuted)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
