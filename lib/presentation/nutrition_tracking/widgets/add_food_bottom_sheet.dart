import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/gemini_service.dart';

class AddFoodBottomSheet extends StatefulWidget {
  final String mealType;
  final Function(Map<String, dynamic>) onFoodAdded;
  final GeminiService geminiService;

  const AddFoodBottomSheet({
    Key? key,
    required this.mealType,
    required this.onFoodAdded,
    required this.geminiService,
  }) : super(key: key);

  @override
  State<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<AddFoodBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  XFile? _capturedImage;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (!await _requestCameraPermission()) return;

    try {
      _cameras = await availableCameras();
      if (_cameras != null && (_cameras as List).isNotEmpty) {
        final camera = kIsWeb
            ? (_cameras as List).firstWhere(
                (c) =>
                    (c as CameraDescription).lensDirection ==
                    CameraLensDirection.front,
                orElse: () => (_cameras as List).first) as CameraDescription
            : (_cameras as List).firstWhere(
                (c) =>
                    (c as CameraDescription).lensDirection ==
                    CameraLensDirection.back,
                orElse: () => (_cameras as List).first) as CameraDescription;

        _cameraController = CameraController(
            camera, kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high);

        await _cameraController!.initialize();
        await _applySettings();

        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    return (await Permission.camera.request()).isGranted;
  }

  Future<void> _applySettings() async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      if (!kIsWeb) {
        await _cameraController!.setFlashMode(FlashMode.auto);
      }
    } catch (e) {
      debugPrint('Camera settings error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() => _capturedImage = photo);
      await _analyzeImageWithGemini(File(photo.path));
    } catch (e) {
      debugPrint('Photo capture error: $e');
      _showErrorDialog('Failed to capture photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _capturedImage = image);
        await _analyzeImageWithGemini(File(image.path));
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImageWithGemini(File imageFile) async {
    setState(() => _isAnalyzing = true);

    try {
      final analysis = await widget.geminiService.analyzeFoodImage(
        imageFile,
        additionalPrompt:
            'This image is for ${widget.mealType}. Please provide detailed nutritional analysis.',
      );

      setState(() => _isAnalyzing = false);

      if (analysis.foods.isNotEmpty) {
        _showFoodSelectionDialog(analysis);
      } else {
        _showErrorDialog(
            'No food items detected in the image. Please try another photo.');
      }
    } on GeminiException catch (e) {
      setState(() => _isAnalyzing = false);
      _showErrorDialog('AI Analysis failed: ${e.message}');
    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showErrorDialog('Analysis error: $e');
    }
  }

  void _showFoodSelectionDialog(NutritionAnalysis analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🤖 AI Food Recognition Results'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detected ${analysis.foods.length} food item(s):',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                constraints: BoxConstraints(maxHeight: 40.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: analysis.foods.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final food = analysis.foods[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        food.name,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${food.quantity} ${food.unit}'),
                          Text(
                            '${food.calories} cal • P: ${food.protein.toStringAsFixed(1)}g • C: ${food.carbs.toStringAsFixed(1)}g • F: ${food.fat.toStringAsFixed(1)}g',
                            style: AppTheme.lightTheme.textTheme.bodySmall,
                          ),
                          LinearProgressIndicator(
                            value: food.confidence,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              food.confidence > 0.7
                                  ? Colors.green
                                  : food.confidence > 0.4
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                          Text(
                            'Confidence: ${(food.confidence * 100).toInt()}%',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _addFoodItem(food.toMealFormat());
                        },
                        child: Text('Add'),
                      ),
                    );
                  },
                ),
              ),
              if (analysis.analysisNotes.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Notes:',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        analysis.analysisNotes,
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          if (analysis.foods.length > 1)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Add all foods
                for (final food in analysis.foods) {
                  _addFoodItem(food.toMealFormat());
                }
              },
              child: Text('Add All'),
            ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text('Analysis Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _searchFood(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    // For manual search, we'll use a simple food database
    // In a real app, this could also use Gemini for food search
    Future.delayed(const Duration(milliseconds: 500), () {
      final results = _getFoodSuggestions(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> _getFoodSuggestions(String query) {
    final commonFoods = [
      {
        'name': 'Grilled Chicken Breast',
        'calories': 165,
        'protein': 31.0,
        'carbs': 0.0,
        'fat': 3.6,
        'fiber': 0.0,
        'sugar': 0.0,
        'sodium': 74,
        'unit': '100g',
      },
      {
        'name': 'Brown Rice',
        'calories': 111,
        'protein': 2.6,
        'carbs': 23.0,
        'fat': 0.9,
        'fiber': 1.8,
        'sugar': 0.4,
        'sodium': 5,
        'unit': '100g',
      },
      {
        'name': 'Greek Yogurt',
        'calories': 100,
        'protein': 17.0,
        'carbs': 6.0,
        'fat': 0.0,
        'fiber': 0.0,
        'sugar': 6.0,
        'sodium': 60,
        'unit': '170g',
      },
      {
        'name': 'Banana',
        'calories': 105,
        'protein': 1.3,
        'carbs': 27.0,
        'fat': 0.4,
        'fiber': 3.1,
        'sugar': 14.4,
        'sodium': 1,
        'unit': '1 medium',
      },
      {
        'name': 'Avocado',
        'calories': 234,
        'protein': 2.9,
        'carbs': 12.0,
        'fat': 21.0,
        'fiber': 10.0,
        'sugar': 1.0,
        'sodium': 11,
        'unit': '1 medium',
      },
    ];

    return commonFoods
        .where((food) => (food['name'] as String)
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
  }

  void _addFoodItem(Map<String, dynamic> food) {
    final foodWithQuantity = Map<String, dynamic>.from(food);
    foodWithQuantity['quantity'] = 1;
    widget.onFoodAdded(foodWithQuantity);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 12.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Add Food to ${widget.mealType}',
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(
                        icon: CustomIconWidget(
                          iconName: 'camera_alt',
                          color: AppTheme.lightTheme.primaryColor,
                          size: 20,
                        ),
                        text: 'AI Scan',
                      ),
                      Tab(
                        icon: CustomIconWidget(
                          iconName: 'search',
                          color: AppTheme.lightTheme.primaryColor,
                          size: 20,
                        ),
                        text: 'Manual Search',
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCameraTab(),
                        _buildSearchTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraTab() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Text(
            '📱 Powered by Google Gemini AI',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    if (_isCameraInitialized && _cameraController != null)
                      Positioned.fill(
                        child: CameraPreview(_cameraController!),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'camera_alt',
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Initializing AI-powered camera...',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    if (_isAnalyzing)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.8),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: AppTheme.lightTheme.primaryColor,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'AI is analyzing your food...',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  'This may take a few seconds',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _pickImageFromGallery,
                icon: CustomIconWidget(
                  iconName: 'photo_library',
                  color: Colors.white,
                  size: 20,
                ),
                label: Text('Gallery'),
              ),
              FloatingActionButton(
                onPressed: _isCameraInitialized && !_isAnalyzing
                    ? _capturePhoto
                    : null,
                backgroundColor: _isAnalyzing
                    ? Colors.grey
                    : AppTheme.lightTheme.primaryColor,
                child: _isAnalyzing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : CustomIconWidget(
                        iconName: 'camera',
                        color: Colors.white,
                        size: 28,
                      ),
              ),
              ElevatedButton.icon(
                onPressed: _isAnalyzing
                    ? null
                    : () => setState(() => _capturedImage = null),
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: Colors.white,
                  size: 20,
                ),
                label: Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for food...',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'search',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _searchFood('');
                      },
                      icon: CustomIconWidget(
                        iconName: 'clear',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    )
                  : null,
            ),
            onChanged: _searchFood,
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: _isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 2.h),
                        Text('Searching...'),
                      ],
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'search',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 48,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Start typing to search for food'
                                  : 'No results found',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final food = _searchResults[index];
                          return ListTile(
                            title: Text(food['name'] as String),
                            subtitle: Text(
                              '${food['calories']} cal • P: ${food['protein']}g • C: ${food['carbs']}g • F: ${food['fat']}g',
                            ),
                            trailing: TextButton(
                              onPressed: () => _addFoodItem(food),
                              child: Text('Add'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
