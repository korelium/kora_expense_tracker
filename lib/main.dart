import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'screens/dashboard_screen.dart';

// Global theme notifier for dark/light mode switching
class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

final ThemeNotifier themeNotifier = ThemeNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const KoraExpenseTrackerApp());
}

class KoraExpenseTrackerApp extends StatelessWidget {
  const KoraExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return MaterialApp(
          title: 'Kora Expense Tracker',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: themeNotifier.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const DashboardScreen(),
        );
      },
    );
  }

  // PROFESSIONAL LIGHT THEME
  ThemeData _lightTheme() {
    return ThemeData(
      primarySwatch: MaterialColor(0xFF1A237E, {
        50: const Color(0xFFE8EAF6),
        100: const Color(0xFFC5CAE9),
        200: const Color(0xFF9FA8DA),
        300: const Color(0xFF7986CB),
        400: const Color(0xFF5C6BC0),
        500: const Color(0xFF3F51B5),
        600: const Color(0xFF3949AB),
        700: const Color(0xFF303F9F),
        800: const Color(0xFF283593),
        900: const Color(0xFF1A237E),
      }),
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1A237E),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      visualDensity: VisualDensity.adaptivePlatformDensity,

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 8,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF1A237E),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }

  // PROFESSIONAL DARK THEME
  ThemeData _darkTheme() {
    return ThemeData(
      primarySwatch: MaterialColor(0xFF1A237E, {
        50: const Color(0xFF1A1A2E),
        100: const Color(0xFF16213E),
        200: const Color(0xFF0F3460),
        300: const Color(0xFF1A237E),
        400: const Color(0xFF3949AB),
        500: const Color(0xFF5C6BC0),
        600: const Color(0xFF7986CB),
        700: const Color(0xFF9FA8DA),
        800: const Color(0xFFC5CAE9),
        900: const Color(0xFFE8EAF6),
      }),
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF1A237E),
      scaffoldBackgroundColor: const Color(0xFF121212),
      visualDensity: VisualDensity.adaptivePlatformDensity,

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 8,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E1E1E),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2E2E2E),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF1A237E),
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 8,
      ),
    );
  }
}
