import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // ==========================================================
    // TO RECEIVE REAL SMS: Paste your Firebase Web Config below!
    // ==========================================================
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCuqLLPzTLkytAw-yvVY_6Ux32pqyjAQcM",
        authDomain: "ehr-companion-for-asha.firebaseapp.com",
        projectId: "ehr-companion-for-asha",
        storageBucket: "ehr-companion-for-asha.firebasestorage.app",
        messagingSenderId: "730772401193",
        appId: "1:730772401193:web:47857e1c16c48d83060038",
      ),
    );
  } catch (e) {
    debugPrint('Firebase core initialisation fallback: $e');
  }

  try {
    await Supabase.initialize(
      url: 'https://placeholder-project.supabase.co',
      anonKey: 'placeholder-anon-key',
    );
  } catch (e) {
    debugPrint('Supabase initialisation fallback: $e');
  }

  runApp(
    const ProviderScope(
      child: AshaCareApp(),
    ),
  );
}

class AshaCareApp extends StatelessWidget {
  const AshaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ASHA CARE+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, // Enforce light theme only
      routerConfig: appRouter,
    );
  }
}
