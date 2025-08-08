import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize anonymous authentication
  await _initializeAnonymousAuth();

  runApp(const ProviderScope(child: WordleSolverApp()));
}

Future<void> _initializeAnonymousAuth() async {
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Anonymous auth failed: $e');
  }
}

class WordleSolverApp extends StatelessWidget {
  const WordleSolverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordle Solver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF3AA6FF),
          onPrimary: Colors.white,
          secondary: Color(0xFFFF70A6),
          onSecondary: Colors.white,
          error: Color(0xFFB00020),
          onError: Colors.white,
          background: Colors.white,
          onBackground: Color(0xFF1A1C1E),
          surface: Colors.white,
          onSurface: Color(0xFF1A1C1E),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3AA6FF),
          secondary: Color(0xFFFF70A6),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const HomeScreen(),
    );
  }
}
