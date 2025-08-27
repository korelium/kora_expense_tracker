import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const KoraExpenseTrackerApp());
}

class KoraExpenseTrackerApp extends StatelessWidget {
  const KoraExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kora Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // NEW PROFESSIONAL COLOR SCHEME
        primarySwatch: MaterialColor(0xFF1A237E, <int, Color>{
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
      ),
      home: const DashboardScreen(),
    );
  }
}
