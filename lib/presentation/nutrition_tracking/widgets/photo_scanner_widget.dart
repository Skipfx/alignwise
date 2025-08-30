import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/gemini_service.dart';
import '../../../services/supabase_service.dart';

class PhotoScannerWidget extends StatefulWidget {
  final String mealType;
  final Function(Map<String, dynamic>) onFoodScanned;
  final VoidCallback onClose;

  const PhotoScannerWidget({
    super.key,
    required this.mealType,
    required this.onFoodScanned,
    required this.onClose,
  });

  @override
  State<PhotoScannerWidget> createState() => _PhotoScannerWidgetState();
}

class _PhotoScannerWidgetState extends State<PhotoScannerWidget>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isFlashOn = false;
  bool _isAnalyzing = false;
  String _scanMessage = 'Position food within the frame';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestCameraPermission();
  }

  void _initializeAnimations() {
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

  Future<void> _captureAndAnalyzePhoto() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _scanMessage = 'Analyzing food with AI...';
    });

    _pulseController.repeat(reverse: true);

    try {
      XFile? photo;

      if (_cameraController != null && _isInitialized) {
        // Capture from camera
        photo = await _cameraController!.takePicture();
      } else {
        // Fallback to image picker
        photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
      }

      if (photo != null) {
        await _processPhoto(photo);
      } else {
        _onAnalysisError('No photo captured');
      }
    } catch (e) {
      debugPrint('Photo capture error: $e');
      _onAnalysisError('Failed to capture photo');
    }
  }

  Future<void> _selectFromGallery() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _scanMessage = 'Analyzing selected image...';
    });

    _pulseController.repeat(reverse: true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (photo != null) {
        await _processPhoto(photo);
      } else {
        _onAnalysisError('No image selected');
      }
    } catch (e) {
      debugPrint('Gallery selection error: $e');
      _onAnalysisError('Failed to select image');
    }
  }

  Future<void> _processPhoto(XFile photo) async {
    try {
      // Upload photo to Supabase storage
      String? photoUrl;
      try {
        final supabaseService = SupabaseService.instance;
        final userId = supabaseService.currentUser?.id;
        if (userId != null) {
          final fileName =
              'food_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final filePath = '$userId/food_scans/$fileName';

          if (kIsWeb) {
            final bytes = await photo.readAsBytes();
            await supabaseService.client.storage
                .from('user-files')
                .uploadBinary(filePath, bytes);
          } else {
            final file = File(photo.path);
            await supabaseService.client.storage
                .from('user-files')
                .upload(filePath, file);
          }

          photoUrl = supabaseService.client.storage
              .from('user-files')
              .getPublicUrl(filePath);
        }
      } catch (e) {
        debugPrint('Storage upload error: $e');
      }

      // Analyze photo with Gemini AI
      File imageFile;
      if (kIsWeb) {
        // For web, create a temporary file from bytes
        final bytes = await photo.readAsBytes();
        imageFile = File.fromRawPath(bytes);
      } else {
        imageFile = File(photo.path);
      }

      final analysis = await _geminiService.analyzeFoodImage(
        imageFile,
        additionalPrompt:
            'Analyze this food image for ${widget.mealType} meal tracking. Focus on identifying individual food items and their nutritional content.',
      );

      if (analysis.foods.isNotEmpty) {
        _onFoodDetected(analysis, photoUrl);
      } else {
        _onAnalysisError('No food items detected in image');
      }
    } on GeminiException catch (e) {
      debugPrint('Gemini analysis error: ${e.message}');
      _onAnalysisError('AI analysis failed: ${e.message}');
    } catch (e) {
      debugPrint('Photo analysis error: $e');
      _onAnalysisError('Failed to analyze photo');
    }
  }

  void _onFoodDetected(NutritionAnalysis analysis, String? photoUrl) {
    HapticFeedback.lightImpact();
    _pulseController.stop();

    setState(() {
      _isAnalyzing = false;
      _scanMessage = 'Food detected!';
    });

    // Show analysis results and let user select foods
    _showAnalysisResults(analysis, photoUrl);
  }

  void _onAnalysisError(String error) {
    HapticFeedback.selectionClick();
    _pulseController.stop();

    setState(() {
      _isAnalyzing = false;
      _scanMessage = error;
    });

    // Reset message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _scanMessage = 'Position food within the frame';
        });
      }
    });
  }

  void _showAnalysisResults(NutritionAnalysis analysis, String? photoUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'restaurant_menu',
              color: Colors.green,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text('Food Analysis Results'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${analysis.foods.length} food item(s) detected',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                constraints: BoxConstraints(maxHeight: 40.h),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: analysis.foods.length,
                  itemBuilder: (context, index) {
                    final food = analysis.foods[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 1.h),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.1),
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          food.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${food.calories} cal • ${food.protein.toStringAsFixed(1)}g protein\n${food.quantity} ${food.unit} • Confidence: ${(food.confidence * 100).toInt()}%',
                        ),
                        trailing: Checkbox(
                          value: true,
                          onChanged: (value) {
                            // TODO: Implement individual food selection
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (analysis.analysisNotes.isNotEmpty) ...[
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AI Notes: ${analysis.analysisNotes}',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                ),
              ],
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Calories:'),
                    Text(
                      '${analysis.totalEstimatedCalories} kcal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Add all detected foods as a combined meal
              final combinedFood = {
                'name': '${analysis.foods.length} food items',
                'calories': analysis.totalEstimatedCalories,
                'protein': analysis.foods
                    .fold<double>(0.0, (sum, food) => sum + food.protein),
                'carbs': analysis.foods
                    .fold<double>(0.0, (sum, food) => sum + food.carbs),
                'fat': analysis.foods
                    .fold<double>(0.0, (sum, food) => sum + food.fat),
                'fiber': analysis.foods
                    .fold<double>(0.0, (sum, food) => sum + food.fiber),
                'photo_url': photoUrl,
                'ai_analysis': analysis.analysisNotes,
              };

              widget.onFoodScanned(combinedFood);
              widget.onClose();
            },
            child: Text('Add All Foods'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
                          'Initializing AI Food Scanner...',
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
                      onTap: widget.onClose,
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
                          'AI Food Scanner',
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

            // Scanning Frame
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isAnalyzing ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 80.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isAnalyzing
                              ? AppTheme.lightTheme.colorScheme.primary
                              : Colors.white,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          // Corner indicators
                          ...List.generate(4, (index) {
                            final isTop = index < 2;
                            final isLeft = index % 2 == 0;
                            return Positioned(
                              top: isTop ? -2 : null,
                              bottom: !isTop ? -2 : null,
                              left: isLeft ? -2 : null,
                              right: !isLeft ? -2 : null,
                              child: Container(
                                width: 10.w,
                                height: 10.w,
                                decoration: BoxDecoration(
                                  color: _isAnalyzing
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: isTop && isLeft
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                    topRight: isTop && !isLeft
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                    bottomLeft: !isTop && isLeft
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                    bottomRight: !isTop && !isLeft
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Center icon
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: CustomIconWidget(
                                iconName: 'restaurant_menu',
                                color: Colors.white,
                                size: 8.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Controls
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
                          onTap: _isAnalyzing ? null : _selectFromGallery,
                          child: Column(
                            children: [
                              Container(
                                width: 15.w,
                                height: 15.w,
                                decoration: BoxDecoration(
                                  color: _isAnalyzing
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
                          onTap: _captureAndAnalyzePhoto,
                          child: Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              color: _isAnalyzing
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
                            child: _isAnalyzing
                                ? SizedBox(
                                    width: 8.w,
                                    height: 8.w,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : CustomIconWidget(
                                    iconName: 'camera_alt',
                                    color: Colors.white,
                                    size: 8.w,
                                  ),
                          ),
                        ),

                        // Manual Add Button
                        GestureDetector(
                          onTap: _isAnalyzing ? null : widget.onClose,
                          child: Column(
                            children: [
                              Container(
                                width: 15.w,
                                height: 15.w,
                                decoration: BoxDecoration(
                                  color: _isAnalyzing
                                      ? Colors.grey.withValues(alpha: 0.6)
                                      : Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: CustomIconWidget(
                                  iconName: 'edit',
                                  color: Colors.white,
                                  size: 7.w,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Manual',
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
