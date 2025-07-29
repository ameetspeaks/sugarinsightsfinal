import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      // Primary color scheme
      primaryColor: AppColors.primaryColor,
      primarySwatch: _createMaterialColor(AppColors.primaryColor),
      
      // Scaffold background
      scaffoldBackgroundColor: AppColors.appBackground,
      
      // App bar theme - Medical grade with high contrast
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(
          color: AppColors.white,
          size: 24,
        ),
      ),
      
      // Elevated button theme - High contrast for accessibility
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Lufga',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(120, 48), // Minimum touch target size
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          side: const BorderSide(color: AppColors.primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Lufga',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          minimumSize: const Size(120, 48),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          textStyle: const TextStyle(
            fontFamily: 'Lufga',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(88, 44),
        ),
      ),
      
      // Input decoration theme - Medical grade with clear focus states
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.mutedGrey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.mutedGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.highRange, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.highRange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          fontFamily: 'Lufga',
          color: AppColors.disabledPlaceholder,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Lufga',
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: 'Lufga',
          color: AppColors.primaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Text theme - High contrast for accessibility
      textTheme: const TextTheme(
        // Display styles for large headings
        displayLarge: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0,
          height: 1.4,
        ),
        
        // Headline styles
        headlineLarge: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0,
          height: 1.4,
        ),
        
        // Title styles
        titleLarge: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        
        // Body styles
        bodyLarge: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        
        // Label styles
        labelLarge: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Lufga',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.1,
          height: 1.4,
        ),
      ),
      
      // Card theme - Medical grade with subtle shadows
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 2,
        shadowColor: AppColors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryColor,
        selectedItemColor: AppColors.white,
        unselectedItemColor: AppColors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Color scheme - High contrast for accessibility
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryColor,
        secondary: AppColors.primaryLight,
        surface: AppColors.cardBackground,
        background: AppColors.appBackground,
        error: AppColors.highRange,
        onPrimary: AppColors.white,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: AppColors.white,
        brightness: Brightness.light,
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.mutedGrey,
        thickness: 1,
        space: 1,
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightGrey,
        selectedColor: AppColors.primaryColor,
        disabledColor: AppColors.disabledPlaceholder,
        labelStyle: const TextStyle(
          fontFamily: 'Lufga',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.cardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Lufga',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Lufga',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
      ),
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: 'Lufga',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper method to create MaterialColor from a single color
  static MaterialColor _createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
} 