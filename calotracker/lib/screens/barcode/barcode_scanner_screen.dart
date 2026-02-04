// Barcode Scanner Screen
// Scans product barcodes using Google ML Kit and retrieves nutrition info from Open Food Facts
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../../services/barcode_service.dart';
import '../../services/database_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final VoidCallback? onMealAdded;

  const BarcodeScannerScreen({super.key, this.onMealAdded});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isScanning = true;
  bool _isLoading = false;
  bool _isProcessing = false;
  BarcodeProduct? _product;
  String? _error;
  String? _lastScannedBarcode;
  double _selectedWeight = 100;

  // ML Kit Barcode Scanner
  final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upca,
      BarcodeFormat.upce,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.itf,
      BarcodeFormat.qrCode,
    ],
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = 'Không tìm thấy camera';
        });
        return;
      }

      // Use back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startImageStream();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi khởi tạo camera: $e';
        });
      }
    }
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((CameraImage image) {
      if (!_isScanning || _isProcessing || _isLoading) return;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty && mounted) {
        final barcode = barcodes.first.rawValue;
        if (barcode != null && barcode != _lastScannedBarcode) {
          await _onBarcodeDetected(barcode);
        }
      }
    } catch (e) {
      // Ignore processing errors
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );

      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _onBarcodeDetected(String barcode) async {
    setState(() {
      _isScanning = false;
      _isLoading = true;
      _lastScannedBarcode = barcode;
      _error = null;
    });

    await _cameraController?.stopImageStream();

    // Lookup product from Open Food Facts
    final result = await BarcodeService.lookupProduct(barcode);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess && result.product != null) {
          _product = result.product;
          _selectedWeight = result.product!.servingQuantity;
        } else {
          _error = result.error;
        }
      });
    }
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _isLoading = false;
      _product = null;
      _error = null;
      _lastScannedBarcode = null;
    });
    _startImageStream();
  }

  Future<void> _addToDiary() async {
    if (_product == null) return;

    final meal = BarcodeService.productToMeal(_product!, _selectedWeight);
    await DatabaseService.insertMeal(meal);

    widget.onMealAdded?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${_product!.name}'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Quét mã vạch'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isScanning && _product == null)
            IconButton(
              icon: const Icon(CupertinoIcons.refresh),
              onPressed: _resetScanner,
            ),
        ],
      ),
      body: _product != null
          ? _buildProductResult()
          : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // Camera preview
        if (_isCameraInitialized && _cameraController != null)
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
          )
        else if (_error != null)
          Center(
            child: Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          )
        else
          const Center(
            child: CupertinoActivityIndicator(color: Colors.white),
          ),

        // Overlay
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),

        // Scan area
        Center(
          child: Container(
            width: 280,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isLoading ? AppColors.warningOrange : Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ),

        // Scan line animation
        if (_isScanning && !_isLoading)
          Center(
            child: SizedBox(
              width: 280,
              height: 150,
              child: _ScanLineAnimation(),
            ),
          ),

        // Instructions or loading
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (_isLoading) ...[
                const CupertinoActivityIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Đang tìm sản phẩm từ Open Food Facts...',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ] else if (_error != null && !_isScanning) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        color: Colors.white,
                        onPressed: _resetScanner,
                        child: Text(
                          'Thử lại',
                          style: TextStyle(color: AppColors.errorRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.barcode,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Google ML Kit',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Đặt mã vạch vào khung hình',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hỗ trợ: EAN-13, EAN-8, UPC-A, UPC-E, QR Code',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        // ML Kit badge
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Powered by ML Kit',
                  style: AppTextStyles.caption.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductResult() {
    final product = _product!;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.successGreen),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.successGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Từ Open Food Facts',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.successGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Product info card
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image and name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            product.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                CupertinoIcons.cube_box,
                                size: 32,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.cube_box,
                            size: 32,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: AppTextStyles.heading3,
                            ),
                            if (product.brand.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                product.brand,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Mã: ${product.barcode}',
                              style: AppTextStyles.caption.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            if (product.nutriScore != null) ...[
                              const SizedBox(height: 8),
                              _buildNutriScore(product.nutriScore!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Nutrition info per 100g
                  Text(
                    'Thông tin dinh dưỡng (100g)',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildNutrientItem(
                        'Calories',
                        '${product.caloriesPer100g.toInt()}',
                        'kcal',
                        AppColors.warningOrange,
                      ),
                      _buildNutrientItem(
                        'Protein',
                        product.proteinPer100g.toStringAsFixed(1),
                        'g',
                        AppColors.successGreen,
                      ),
                      _buildNutrientItem(
                        'Carbs',
                        product.carbsPer100g.toStringAsFixed(1),
                        'g',
                        AppColors.primaryBlue,
                      ),
                      _buildNutrientItem(
                        'Fat',
                        product.fatPer100g.toStringAsFixed(1),
                        'g',
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Weight selector
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Khối lượng', style: AppTextStyles.cardTitle),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_selectedWeight > 10) {
                            setState(() => _selectedWeight -= 10);
                          }
                        },
                        icon: const Icon(CupertinoIcons.minus_circle, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_selectedWeight.toInt()}g',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          if (_selectedWeight < 1000) {
                            setState(() => _selectedWeight += 10);
                          }
                        },
                        icon: const Icon(CupertinoIcons.plus_circle, size: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick weight buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [50, 100, 150, 200, 250].map((w) {
                      final isSelected = _selectedWeight == w;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedWeight = w.toDouble()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${w}g',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Calculated nutrition
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Calories cho ${_selectedWeight.toInt()}g:',
                          style: AppTextStyles.bodyMedium,
                        ),
                        Text(
                          '${(product.caloriesPer100g * _selectedWeight / 100).toInt()} kcal',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: Theme.of(context).dividerColor,
                    onPressed: _resetScanner,
                    child: Text(
                      'Quét lại',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: AppColors.successGreen,
                    onPressed: _addToDiary,
                    child: const Text(
                      'Thêm vào nhật ký',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(color: color),
          ),
          Text(
            unit,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutriScore(String score) {
    final colors = {
      'A': Colors.green,
      'B': Colors.lightGreen,
      'C': Colors.amber,
      'D': Colors.orange,
      'E': Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors[score.toUpperCase()] ?? Colors.grey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Nutri-Score $score',
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Scan line animation widget
class _ScanLineAnimation extends StatefulWidget {
  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanLinePainter(_animation.value),
        );
      },
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;

  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.primaryBlue.withValues(alpha: 0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 4));

    final y = size.height * progress;
    canvas.drawRect(Rect.fromLTWH(0, y, size.width, 4), paint);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
