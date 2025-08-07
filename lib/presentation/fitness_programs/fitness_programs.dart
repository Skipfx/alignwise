import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/wellness_service.dart';
import '../../widgets/custom_error_widget.dart';
import './widgets/active_program_card_widget.dart';
import './widgets/featured_program_card_widget.dart';
import './widgets/program_category_card_widget.dart';
import './widgets/program_stats_header_widget.dart';

class FitnessPrograms extends StatefulWidget {
  const FitnessPrograms({super.key});

  @override
  State<FitnessPrograms> createState() => _FitnessProgramsState();
}

class _FitnessProgramsState extends State<FitnessPrograms> {
  final WellnessService _wellnessService = WellnessService();
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _activePrograms = [];
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  String? _errorMessage;

  final List<Map<String, String>> _categories = [
    {
      'name': 'Beginner Foundations',
      'description': 'Perfect starting point',
      'image':
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
      'duration': '8-12 weeks',
      'equipment': 'Bodyweight'
    },
    {
      'name': 'Strength Building',
      'description': 'Build muscle & power',
      'image':
          'https://images.pexels.com/photos/416978/pexels-photo-416978.jpeg?w=400',
      'duration': '6-10 weeks',
      'equipment': 'Weights'
    },
    {
      'name': 'HIIT Challenges',
      'description': 'High intensity training',
      'image':
          'https://images.pixabay.com/photo/2017/08/07/14/02/people-2604149_1280.jpg?w=400',
      'duration': '4-6 weeks',
      'equipment': 'Minimal'
    },
    {
      'name': 'Yoga Flows',
      'description': 'Flexibility & mindfulness',
      'image':
          'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
      'duration': '4-8 weeks',
      'equipment': 'Mat only'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        _wellnessService.getFitnessPrograms(),
        _wellnessService.getActivePrograms(),
        _wellnessService.getProgramStats(),
      ]);

      setState(() {
        _programs = results[0] as List<Map<String, dynamic>>;
        _activePrograms = results[1] as List<Map<String, dynamic>>;
        _userStats = results[2] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? CustomErrorWidget()
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: CustomScrollView(slivers: [
                      SliverAppBar(
                          expandedHeight: 120.0,
                          floating: false,
                          pinned: true,
                          backgroundColor: Colors.white,
                          elevation: 0,
                          flexibleSpace: FlexibleSpaceBar(
                              title: Text('Fitness Programs',
                                  style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                              centerTitle: true),
                          leading: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.black87),
                              onPressed: () => Navigator.pop(context)),
                          actions: [
                            IconButton(
                                icon: const Icon(Icons.search,
                                    color: Colors.black87),
                                onPressed: () {
                                  // TODO: Implement program search
                                }),
                          ]),
                      SliverToBoxAdapter(
                          child: Column(children: [
                        // Program Stats Header
                        ProgramStatsHeaderWidget(
                            totalPrograms: _userStats?['total_programs'] ?? 0,
                            completedPrograms:
                                _userStats?['completed_programs'] ?? 0,
                            currentStreak: _userStats?['current_streak'] ?? 0,
                            totalWorkouts: _userStats?['total_workouts'] ?? 0),

                        const SizedBox(height: 20),

                        // Active Programs Section
                        if (_activePrograms.isNotEmpty) ...[
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(children: [
                                Text('Active Programs',
                                    style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                const Spacer(),
                                TextButton(
                                    onPressed: () {
                                      // TODO: Navigate to full active programs list
                                    },
                                    child: Text('View All',
                                        style: GoogleFonts.inter(
                                            color: Colors.blue[600],
                                            fontWeight: FontWeight.w500))),
                              ])),
                          const SizedBox(height: 12),
                          SizedBox(
                              height: 160,
                              child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _activePrograms.length,
                                  itemBuilder: (context, index) {
                                    final program = _activePrograms[index];
                                    return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 16),
                                        child: ActiveProgramCardWidget(
                                            title: program['title'] ??
                                                'Unknown Program',
                                            currentWeek:
                                                program['current_week'] ?? 1,
                                            totalWeeks:
                                                program['duration_weeks'] ?? 8,
                                            progress: (program[
                                                        'completion_percentage'] ??
                                                    0)
                                                .toDouble(),
                                            nextWorkout:
                                                program['next_workout'] ??
                                                    'Upper Body Focus',
                                            onTap: () {
                                              // TODO: Navigate to program details
                                            }));
                                  })),
                          const SizedBox(height: 24),
                        ],

                        // Featured Programs Section
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(children: [
                              Text('Featured Programs',
                                  style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text('New',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.orange[800]))),
                            ])),
                        const SizedBox(height: 12),
                        SizedBox(
                            height: 220,
                            child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                scrollDirection: Axis.horizontal,
                                itemCount: _programs.length,
                                itemBuilder: (context, index) {
                                  final program = _programs[index];
                                  return Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: FeaturedProgramCardWidget(
                                          title: program['title'] ??
                                              'Unknown Program',
                                          description:
                                              program['description'] ?? '',
                                          difficulty: program['difficulty'] ??
                                              'beginner',
                                          duration:
                                              '${program['duration_weeks'] ?? 8} weeks',
                                          rating: 4.8, // Mock rating
                                          participants:
                                              1250, // Mock participants
                                          imageUrl: program['hero_image_url'] ??
                                              'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
                                          isPremium:
                                              program['is_premium'] ?? false,
                                          onTap: () {
                                            // TODO: Navigate to program details
                                          }));
                                })),

                        const SizedBox(height: 24),

                        // Program Categories Section
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(children: [
                              Text('Program Categories',
                                  style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Icon(Icons.tune,
                                  color: Colors.grey[600], size: 20),
                            ])),
                        const SizedBox(height: 12),
                        GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.85),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              return ProgramCategoryCardWidget(
                                  name: category['name']!,
                                  description: category['description']!,
                                  duration: category['duration']!,
                                  equipment: category['equipment']!,
                                  imageUrl: category['image']!,
                                  programCount: 12, // Mock count
                                  onTap: () {
                                    // TODO: Navigate to category programs
                                  });
                            }),
                        const SizedBox(height: 100),
                      ])),
                    ])),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // TODO: Navigate to custom program builder
            },
            backgroundColor: Colors.blue[600],
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Create Program',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600))));
  }
}