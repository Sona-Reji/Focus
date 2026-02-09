import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FocusApp());
}


class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FOCUS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: const Color(0xFF4A9B8E),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFE0F2F0),
          onPrimaryContainer: const Color(0xFF1E2A32),
          secondary: const Color(0xFFE8836B),
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFFFF0ED),
          onSecondaryContainer: const Color(0xFF1E2A32),
          tertiary: const Color(0xFF4A9B8E),
          onTertiary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: const Color(0xFFF7F9FA),
          onBackground: const Color(0xFF1E2A32),
          surface: const Color(0xFFFFFFFF),
          onSurface: const Color(0xFF1E2A32),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A9B8E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A9B8E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1E2A32)),
          bodyMedium: TextStyle(color: Color(0xFF1E2A32)),
          bodySmall: TextStyle(color: Color(0xFF1E2A32)),
          headlineLarge: TextStyle(color: Color(0xFF1E2A32)),
          headlineMedium: TextStyle(color: Color(0xFF1E2A32)),
          headlineSmall: TextStyle(color: Color(0xFF1E2A32)),
          labelLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
