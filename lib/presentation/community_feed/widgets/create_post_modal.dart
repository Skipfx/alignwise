import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';

class CreatePostModal extends StatefulWidget {
  final VoidCallback onPostCreated;

  const CreatePostModal({
    Key? key,
    required this.onPostCreated,
  }) : super(key: key);

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  String _selectedVisibility = 'friends';
  String _selectedActivityType = 'custom_post';
  bool _isCreatingPost = false;
  List<String> _selectedImages = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info
                  _buildUserInfo(),
                  SizedBox(height: 4.w),
                  
                  // Activity type selector
                  _buildActivityTypeSelector(),
                  SizedBox(height: 4.w),
                  
                  // Title input
                  _buildTitleInput(),
                  SizedBox(height: 4.w),
                  
                  // Description input
                  _buildDescriptionInput(),
                  SizedBox(height: 4.w),
                  
                  // Media attachment section
                  _buildMediaSection(),
                  SizedBox(height: 4.w),
                  
                  // Tags input
                  _buildTagsInput(),
                  SizedBox(height: 4.w),
                  
                  // Visibility selector
                  _buildVisibilitySelector(),
                  SizedBox(height: 6.w),
                  
                  // Achievement toggle
                  _buildAchievementToggle(),
                  SizedBox(height: 6.w),
                  
                  // Create button
                  _buildCreateButton(),
                ]))),
        ]));
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close)),
          Expanded(
            child: Text(
              'Share Your Wellness Journey',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold),
              textAlign: TextAlign.center)),
          SizedBox(width: 48), // Balance the close button
        ]));
  }

  Widget _buildUserInfo() {
    final currentUser = SupabaseService.instance.currentUser;
    final userName = currentUser?.userMetadata?['full_name'] ?? 'User';
    final userAvatar = currentUser?.userMetadata?['avatar_url'];

    return Row(
      children: [
        CircleAvatar(
          radius: 6.w,
          
          backgroundImage: userAvatar != null
              ? CachedNetworkImageProvider(userAvatar)
              : null,
          child: userAvatar == null
              ? Text(
                  userName.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold))
              : null),
        SizedBox(width: 3.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600)),
            Text(
              'Share with $_selectedVisibility',
              style: GoogleFonts.inter(
                fontSize: 12.sp)),
          ]),
      ]);
  }

  Widget _buildActivityTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Type',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600)),
        SizedBox(height: 2.w),
        Wrap(
          spacing: 2.w,
          runSpacing: 2.w,
          children: [
            _buildActivityTypeChip('custom_post', 'General Post', Icons.edit),
            _buildActivityTypeChip('workout_completed', 'Workout', Icons.fitness_center),
            _buildActivityTypeChip('meditation_session', 'Meditation', Icons.self_improvement),
            _buildActivityTypeChip('meal_logged', 'Meal', Icons.restaurant),
            _buildActivityTypeChip('goal_achieved', 'Achievement', Icons.emoji_events),
          ]),
      ]);
  }

  Widget _buildActivityTypeChip(String value, String label, IconData icon) {
    final isSelected = _selectedActivityType == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedActivityType = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey.shade600,
              )),
          ])));
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600)),
        SizedBox(height: 2.w),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'What did you accomplish today?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue)),
          ),
          style: GoogleFonts.inter(fontSize: 14.sp)),
      ]);
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600)),
        SizedBox(height: 2.w),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share more details about your wellness journey...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue)),
          ),
          style: GoogleFonts.inter(fontSize: 14.sp)),
      ]);
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add Photos',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: _addPhoto,
              icon: Icon(Icons.add_photo_alternate, size: 16.sp),
              label: Text('Add Photo'),
              style: TextButton.styleFrom()),
          ]),
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(height: 2.w),
          Container(
            height: 20.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 30.w,
                  margin: EdgeInsets.only(right: 2.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: _selectedImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity)),
                      Positioned(
                        top: 1.w,
                        right: 1.w,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: EdgeInsets.all(1.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(153),
                              shape: BoxShape.circle),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12.sp)))),
                    ]));
              })),
        ],
      ]);
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags (Optional)',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600)),
        SizedBox(height: 2.w),
        TextField(
          controller: _tagsController,
          decoration: InputDecoration(
            hintText: 'fitness, motivation, wellness (separate with commas)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue)),
            prefixIcon: Icon(Icons.tag)),
          style: GoogleFonts.inter(fontSize: 14.sp)),
      ]);
  }

  Widget _buildVisibilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who can see this?',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600)),
        SizedBox(height: 2.w),
        Row(
          children: [
            _buildVisibilityOption('public', 'Public', Icons.public),
            SizedBox(width: 4.w),
            _buildVisibilityOption('friends', 'Friends', Icons.people),
            SizedBox(width: 4.w),
            _buildVisibilityOption('private', 'Just Me', Icons.lock),
          ]),
      ]);
  }

  Widget _buildVisibilityOption(String value, String label, IconData icon) {
    final isSelected = _selectedVisibility == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedVisibility = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: isSelected ? Colors.blue : Colors.grey.shade600),
            SizedBox(width: 2.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey.shade600)),
          ])));
  }

  Widget _buildAchievementToggle() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withAlpha(77))),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.orange),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark as Achievement',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600)),
                Text(
                  'Celebrate a milestone or special accomplishment',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp)),
              ])),
          Switch(
            value: false, // You can add state for this
            onChanged: (value) {
              // Handle achievement toggle
            }),
        ]));
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreatingPost ? null : _createPost,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 4.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25))),
        child: _isCreatingPost
            ? SizedBox(
                height: 20.sp,
                width: 20.sp,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share, size: 16.sp),
                  SizedBox(width: 2.w),
                  Text(
                    'Share with Community',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600)),
                ])));
  }

  void _addPhoto() {
    // Mock implementation - add sample images
    setState(() {
      _selectedImages.add('https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400');
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createPost() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add a title'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isCreatingPost = true);

    try {
      final supabase = SupabaseService.instance.client;
      final currentUser = SupabaseService.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Create activity post
      await supabase.from('community_activities').insert({
        'user_id': currentUser.id,
        'activity_type': _selectedActivityType,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'media_urls': _selectedImages,
        'visibility': _selectedVisibility,
        'tags': tags,
        'is_achievement': false, // You can add state for this
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post shared successfully!'),
          backgroundColor: Colors.green));

      widget.onPostCreated();
    } catch (error) {
      print('Error creating post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create post'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isCreatingPost = false);
    }
  }
}