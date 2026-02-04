// Camera Scan Screen
// AI-powered food recognition from camera
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/meal.dart';
import '../../models/chat_message.dart';
import '../../services/database_service.dart';
import '../../services/food_recognition_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/nutrition_pie_chart.dart';

class CameraScanScreen extends StatefulWidget {
  final VoidCallback? onMealAdded;

  const CameraScanScreen({super.key, this.onMealAdded});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  NutritionData? _nutritionData;
  List<RecognizedFood>? _recognizedFoods;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openCamera();
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _error = null;
        });
        _scanImage();
      } else {
        // User cancelled
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể mở camera: $e';
      });
    }
  }

  Future<void> _openGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _error = null;
          _nutritionData = null;
          _recognizedFoods = null;
        });
        _scanImage();
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể mở thư viện: $e';
      });
    }
  }

  Future<void> _scanImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Step 1: Recognize food from image using AI
    final recognitionResult = await FoodRecognitionService.recognizeFood(
      _imageFile!,
    );

    if (!recognitionResult.isSuccess ||
        recognitionResult.foods == null ||
        recognitionResult.foods!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error =
              recognitionResult.error ??
              'Không nhận diện được thức ăn trong ảnh';
        });
      }
      return;
    }

    // Step 2: Get nutrition data for recognized foods
    final nutritionResult = await FoodRecognitionService.getNutritionForFoods(
      recognitionResult.foods!,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _recognizedFoods = recognitionResult.foods;
        if (nutritionResult.isSuccess) {
          _nutritionData = nutritionResult.data;
        } else {
          _error = nutritionResult.error;
        }
      });
    }
  }

  Future<void> _addMealToDiary() async {
    if (_nutritionData == null) return;

    for (final food in _nutritionData!.foods) {
      final meal = Meal(
        dateTime: DateTime.now(),
        foodName: food.name,
        weight: food.weight,
        calories: food.calories,
        protein:
            _nutritionData!.protein != null
                ? _nutritionData!.protein! / _nutritionData!.foods.length
                : null,
        carbs:
            _nutritionData!.carbs != null
                ? _nutritionData!.carbs! / _nutritionData!.foods.length
                : null,
        fat:
            _nutritionData!.fat != null
                ? _nutritionData!.fat! / _nutritionData!.foods.length
                : null,
        source: 'camera',
      );
      await DatabaseService.insertMeal(meal);
    }

    widget.onMealAdded?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Đã thêm ${_nutritionData!.calories.toInt()} kcal vào nhật ký!',
              ),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Image preview
            Expanded(child: _buildImagePreview()),

            // Results or actions
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Quét món ăn',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _openGallery,
            icon: const Icon(CupertinoIcons.photo, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.camera, size: 80, color: Colors.white30),
            const SizedBox(height: 16),
            Text(
              'Chụp ảnh món ăn',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openCamera,
              icon: const Icon(CupertinoIcons.camera_fill),
              label: const Text('Mở camera'),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(_imageFile!, fit: BoxFit.cover),
        ),

        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: 20,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang phân tích...',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Error overlay
        if (_error != null && !_isLoading)
          Container(
            color: Colors.black54,
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 48,
                    color: AppColors.warningOrange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _scanImage,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomSection() {
    if (_nutritionData == null || _isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openCamera,
                icon: const Icon(CupertinoIcons.camera_fill),
                label: const Text('Chụp lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Flexible(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Result header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: AppColors.successGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Kết quả nhận diện',
                      style: AppTextStyles.cardTitle,
                    ),
                  ),
                  Text(
                    '${_nutritionData!.calories.toInt()} kcal',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // AI Confidence indicator (from _recognizedFoods)
              if (_recognizedFoods != null && _recognizedFoods!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.sparkles,
                        size: 14,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI Confidence: ${(_recognizedFoods!.first.confidence * 100).toInt()}%',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Foods detected
              ...(_nutritionData!.foods.map(
                (food) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🍽️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.name,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (food.weight != null)
                              Text(
                                '${food.weight?.toInt()}g',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${food.calories.toInt()} kcal',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 8),

              // Macros
              if (_nutritionData!.hasMacros)
                MacroBars(
                  protein: _nutritionData!.protein ?? 0,
                  carbs: _nutritionData!.carbs ?? 0,
                  fat: _nutritionData!.fat ?? 0,
                ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openCamera,
                      icon: const Icon(CupertinoIcons.camera_fill, size: 18),
                      label: const Text('Quét lại'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _addMealToDiary,
                      icon: const Icon(CupertinoIcons.plus, size: 18),
                      label: const Text('Thêm vào nhật ký'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
