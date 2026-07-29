import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Purple, White, Aqua Color Tokens
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color primaryDarkPurple = Color(0xFF6D28D9);
  static const Color accentAqua = Color(0xFF06B6D4);
  static const Color accentAquaLight = Color(0xFFECFEFF);

  // Dark Mode Colors
  static const Color darkScaffoldBg = Color(0xFF030712);
  static const Color darkCardBg = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);

  // Light Mode Colors
  static const Color lightScaffoldBg = Color(0xFFF8FAFC);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);

  // Border Colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF1F2937);

  // Backward compatibility aliases
  static const Color primaryAccent = primaryPurple;
  static const Color secondary = accentAqua;
  static const Color cardBg = darkCardBg;
  static const Color surface = darkSurface;
  static const Color scaffoldBg = darkScaffoldBg;

  // Gradients
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF030712),
      Color(0xFF111827),
      Color(0xFF020408),
    ],
  );

  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFE2E8F0),
      Color(0xFFCBD5E1),
    ],
  );

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: primaryPurple,
      cardColor: darkCardBg,
      textTheme: GoogleFonts.outfitTextTheme(baseTextTheme).copyWith(
        headlineLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimaryDark),
        headlineMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimaryDark),
        titleLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimaryDark),
        titleMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryDark),
        bodyLarge: const TextStyle(fontSize: 12, color: textPrimaryDark),
        bodyMedium: const TextStyle(fontSize: 11, color: textSecondary),
        bodySmall: const TextStyle(fontSize: 9, color: textSecondary),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: accentAqua,
        surface: darkSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      cardTheme: CardTheme(
        color: darkCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderDark),
        ),
        elevation: 2,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A0A0C),
        selectedItemColor: primaryPurple,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: primaryPurple,
      cardColor: lightCardBg,
      textTheme: GoogleFonts.outfitTextTheme(baseTextTheme).copyWith(
        headlineLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimaryLight),
        headlineMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimaryLight),
        titleLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimaryLight),
        titleMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryLight),
        bodyLarge: const TextStyle(fontSize: 12, color: textPrimaryLight),
        bodyMedium: const TextStyle(fontSize: 11, color: textSecondary),
        bodySmall: const TextStyle(fontSize: 9, color: textSecondary),
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryPurple,
        secondary: accentAqua,
        surface: lightSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      cardTheme: CardTheme(
        color: lightCardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight),
        ),
        elevation: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryPurple,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class GradientScaffold extends ConsumerWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.darkGradient : AppTheme.lightGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return IconButton(
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Night Mode',
      icon: Icon(
        isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
        color: isDark ? Colors.amber : AppTheme.primaryPurple,
      ),
      onPressed: () {
        ref.read(themeProvider.notifier).toggleTheme();
      },
    );
  }
}
