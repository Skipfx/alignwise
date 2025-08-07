import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../services/gemini_service.dart';

class BarcodeScanner extends StatefulWidget {
  const BarcodeScanner({Key? key}) : super(key: key);

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isFlashOn = false;
  bool _isScanning = false;
  String _scanMessage = 'Align barcode within frame';
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestCameraPermission();
  }

  void _initializeAnimations() {
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scanLineController.repeat(reverse: true);
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) {
      _initializeCamera();
      return true;
    }

    final status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
      return true;
    } else {
      setState(() {
        _scanMessage = 'Camera permission required';
      });
      return false;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _scanMessage = 'No camera available';
        });
        return;
      }

      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first)
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first);

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _applySettings();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _scanMessage = 'Camera initialization failed';
      });
    }
  }

  Future<void> _applySettings() async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      if (!kIsWeb) {
        try {
          await _cameraController!.setFlashMode(FlashMode.off);
        } catch (e) {
          // Flash not supported on this device
        }
      }
    } catch (e) {
      // Settings not supported
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || kIsWeb) return;

    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });

      await _cameraController!
          .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      setState(() {
        _isFlashOn = false;
      });
    }
  }

  void _simulateBarcodeScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanMessage = 'Scanning with AI...';
    });

    _pulseController.repeat(reverse: true);

    try {
      // Generate a realistic barcode for demo
      final random = Random();
      final barcode =
          '${random.nextInt(900000000) + 100000000}${random.nextInt(900) + 100}';

      // Use Gemini AI to analyze the barcode
      final analysis = await _geminiService.analyzeBarcodeProduct(barcode);

      if (analysis.foods.isNotEmpty) {
        _onBarcodeDetected(analysis.foods.first, barcode);
      } else {
        _onBarcodeNotFound();
      }
    } on GeminiException catch (e) {
      debugPrint('Gemini error: ${e.message}');
      _onBarcodeNotFound();
    } catch (e) {
      debugPrint('Barcode analysis error: $e');
      _onBarcodeNotFound();
    }
  }

  void _onBarcodeDetected(FoodItem foodItem, String barcode) {
    HapticFeedback.lightImpact();
    _pulseController.stop();

    setState(() {
      _isScanning = false;
      _scanMessage = 'Product found!';
    });

    // Show success animation
    _showSuccessOverlay(foodItem, barcode);
  }

  void _onBarcodeNotFound() {
    HapticFeedback.selectionClick();
    _pulseController.stop();

    setState(() {
      _isScanning = false;
      _scanMessage = 'Product not found in database';
    });

    // Reset message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _scanMessage = 'Align barcode within frame';
        });
      }
    });
  }

  void _showSuccessOverlay(FoodItem foodItem, String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: Colors.green,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text('Product Found!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              foodItem.brand != null
                  ? '${foodItem.brand} ${foodItem.name}'
                  : foodItem.name,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text('Barcode: $barcode'),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Calories:'),
                      Text('${foodItem.calories} kcal'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Protein:'),
                      Text('${foodItem.protein.toStringAsFixed(1)}g'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Carbs:'),
                      Text('${foodItem.carbs.toStringAsFixed(1)}g'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fat:'),
                      Text('${foodItem.fat.toStringAsFixed(1)}g'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Per ${foodItem.quantity} ${foodItem.unit}',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (foodItem.confidence < 0.8) ...[
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'warning',
                      color: Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'AI Confidence: ${(foodItem.confidence * 100).toInt()}% - Please verify nutrition values',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(
                context,
                '/nutrition-tracking',
                arguments: {
                  'scannedFood': foodItem.toMealFormat(),
                  'mealType': 'Snacks', // Default to snacks for barcode scans
                },
              );
            },
            child: Text('Add to Nutrition Log'),
          ),
        ],
      ),
    );
  }

  void _openGallery() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        height: 25.h,
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Scan from Gallery',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            Text(
              'Select an image from your gallery to scan for barcodes',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _simulateBarcodeScan();
                    },
                    child: const Text('Select Image'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _searchManually() {
    Navigator.pushReplacementNamed(context, '/nutrition-tracking');
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_isInitialized && _cameraController != null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'camera_alt',
                          color: Colors.white,
                          size: 15.w,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Initializing AI Scanner...',
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Top Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: 'close',
                          color: Colors.white,
                          size: 6.w,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'AI Barcode Scanner',
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Powered by Google Gemini',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    if (!kIsWeb)
                      GestureDetector(
                        onTap: _toggleFlash,
                        child: Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            color: _isFlashOn
                                ? AppTheme.lightTheme.colorScheme.primary
                                : Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: CustomIconWidget(
                            iconName: _isFlashOn ? 'flash_on' : 'flash_off',
                            color: Colors.white,
                            size: 6.w,
                          ),
                        ),
                      )
                    else
                      SizedBox(width: 12.w),
                  ],
                ),
              ),
            ),

            // Scanning Reticle
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isScanning ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 70.w,
                      height: 35.h,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isScanning
                              ? AppTheme.lightTheme.colorScheme.primary
                              : Colors.white,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Corner indicators
                          ...List.generate(4, (index) {
                            final isTop = index < 2;
                            final isLeft = index % 2 == 0;
                            return Positioned(
                              top: isTop ? -1 : null,
                              bottom: !isTop ? -1 : null,
                              left: isLeft ? -1 : null,
                              right: !isLeft ? -1 : null,
                              child: Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: BoxDecoration(
                                  color: _isScanning
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: isTop && isLeft
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                    topRight: isTop && !isLeft
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                    bottomLeft: !isTop && isLeft
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                    bottomRight: !isTop && !isLeft
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Scanning line
                          if (_isInitialized)
                            AnimatedBuilder(
                              animation: _scanLineAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  top: (35.h - 4) * _scanLineAnimation.value,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          _isScanning
                                              ? AppTheme.lightTheme.colorScheme
                                                  .primary
                                              : Colors.white,
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Instruction Text
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _scanMessage,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 3.h),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery Button
                        GestureDetector(
                          onTap: _isScanning ? null : _openGallery,
                          child: Column(
                            children: [
                              Container(
                                width: 15.w,
                                height: 15.w,
                                decoration: BoxDecoration(
                                  color: _isScanning
                                      ? Colors.grey.withValues(alpha: 0.6)
                                      : Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: CustomIconWidget(
                                  iconName: 'photo_library',
                                  color: Colors.white,
                                  size: 7.w,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Gallery',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Scan Button
                        GestureDetector(
                          onTap: _simulateBarcodeScan,
                          child: Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              color: _isScanning
                                  ? AppTheme.lightTheme.colorScheme.primary
                                      .withValues(alpha: 0.8)
                                  : AppTheme.lightTheme.colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.lightTheme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: _isScanning
                                ? SizedBox(
                                    width: 8.w,
                                    height: 8.w,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : CustomIconWidget(
                                    iconName: 'qr_code_scanner',
                                    color: Colors.white,
                                    size: 8.w,
                                  ),
                          ),
                        ),

                        // Manual Search Button
                        GestureDetector(
                          onTap: _isScanning ? null : _searchManually,
                          child: Column(
                            children: [
                              Container(
                                width: 15.w,
                                height: 15.w,
                                decoration: BoxDecoration(
                                  color: _isScanning
                                      ? Colors.grey.withValues(alpha: 0.6)
                                      : Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: CustomIconWidget(
                                  iconName: 'search',
                                  color: Colors.white,
                                  size: 7.w,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Search',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
