import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import './routes/app_routes.dart';
import './services/supabase_service.dart';
import 'core/app_export.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration
  Map<String, dynamic> envConfig = {};
  try {
    final String envString = await rootBundle.loadString('env.json');
    envConfig = json.decode(envString);
  } catch (e) {
    debugPrint('Warning: Could not load env.json file: $e');
  }

  // Initialize Supabase
  try {
    final supabaseUrl = envConfig['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = envConfig['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await SupabaseService.initialize(supabaseUrl, supabaseAnonKey);
      debugPrint('Supabase initialized successfully');
    } else {
      debugPrint('Warning: Supabase configuration not found in env.json');
    }
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: MaterialApp(
              theme: ThemeData(),
              title: 'AlignWise',
              debugShowCheckedModeBanner: false,
              routes: AppRoutes.routes));
    });
  }
}