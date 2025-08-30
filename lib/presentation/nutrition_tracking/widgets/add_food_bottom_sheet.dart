import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/wellness_service.dart';
import './photo_scanner_widget.dart';

class AddFoodBottomSheet extends StatefulWidget {
  final String mealType;
  final Function(Map<String, dynamic>) onFoodAdded;

  const AddFoodBottomSheet({
    super.key,
    required this.mealType,
    required this.onFoodAdded,
  });

  @override
  State<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<AddFoodBottomSheet> {
  final _searchController = TextEditingController();
  final _wellnessService = WellnessService();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showCustomEntry = false;

  // Custom entry controllers
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _searchFood(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _wellnessService.searchFoodItems(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching food: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addCustomFood() {
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text) ?? 0.0;
    final fat = double.tryParse(_fatController.text) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a food name')),
      );
      return;
    }

    final foodData = {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };

    widget.onFoodAdded(foodData);
    Navigator.pop(context);
  }

  void _addFoodItem(Map<String, dynamic> foodItem) {
    final foodData = {
      'name': foodItem['name'] ?? 'Unknown Food',
      'calories': (foodItem['calories_per_100g'] ?? 0),
      'protein': (foodItem['protein_per_100g'] ?? 0.0).toDouble(),
      'carbs': (foodItem['carbs_per_100g'] ?? 0.0).toDouble(),
      'fat': (foodItem['fat_per_100g'] ?? 0.0).toDouble(),
    };

    widget.onFoodAdded(foodData);
    Navigator.pop(context);
  }

  void _openPhotoScanner() {
    Navigator.pop(context); // Close bottom sheet

    showDialog(
      context: context,
      useSafeArea: false,
      barrierDismissible: false,
      builder: (context) => PhotoScannerWidget(
        mealType: widget.mealType,
        onFoodScanned: (food) {
          widget.onFoodAdded(food);
        },
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.symmetric(vertical: 1.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with Scan Photo button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add to ${widget.mealType}',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      // New Scan Photo button
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: _openPhotoScanner,
                          icon: CustomIconWidget(
                            iconName: 'camera_alt',
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Scan Photo',
                        ),
                      ),
                      SizedBox(width: 2.w),
                      TextButton(
                        onPressed: () => setState(
                            () => _showCustomEntry = !_showCustomEntry),
                        child: Text(_showCustomEntry ? 'Search' : 'Manual'),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child:
                  _showCustomEntry ? _buildCustomEntry() : _buildSearchView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchView() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search food items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.lightTheme.primaryColor),
              ),
            ),
            onChanged: _searchFood,
          ),
        ),

        SizedBox(height: 2.h),

        // Search results
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return _buildFoodItem(item);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCustomEntry() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manual Food Entry',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildTextField(
            controller: _nameController,
            label: 'Food Name',
            hint: 'Enter food name',
            icon: Icons.restaurant_menu,
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _caloriesController,
                  label: 'Calories',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  icon: Icons.local_fire_department,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildTextField(
                  controller: _proteinController,
                  label: 'Protein (g)',
                  hint: '0.0',
                  keyboardType: TextInputType.number,
                  icon: Icons.fitness_center,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _carbsController,
                  label: 'Carbs (g)',
                  hint: '0.0',
                  keyboardType: TextInputType.number,
                  icon: Icons.grain,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildTextField(
                  controller: _fatController,
                  label: 'Fat (g)',
                  hint: '0.0',
                  keyboardType: TextInputType.number,
                  icon: Icons.opacity,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          ElevatedButton(
            onPressed: _addCustomFood,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Add Food',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.5.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.lightTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 15.w,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 2.h),
          Text(
            _searchController.text.isEmpty
                ? 'Start typing to search for food items'
                : 'No results found',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isNotEmpty) ...[
            SizedBox(height: 1.h),
            TextButton(
              onPressed: () => setState(() => _showCustomEntry = true),
              child: Text('Add "${_searchController.text}" manually'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Unknown Food';
    final calories = item['calories_per_100g'] ?? 0;
    final protein = item['protein_per_100g'] ?? 0.0;
    final carbs = item['carbs_per_100g'] ?? 0.0;
    final fat = item['fat_per_100g'] ?? 0.0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Icons.restaurant_menu,
            color: AppTheme.lightTheme.primaryColor,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$calories cal • ${protein}g protein • ${carbs}g carbs • ${fat}g fat',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Icon(
          Icons.add_circle,
          color: AppTheme.lightTheme.primaryColor,
        ),
        onTap: () => _addFoodItem(item),
      ),
    );
  }
}
