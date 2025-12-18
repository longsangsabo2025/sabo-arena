import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/design_system/design_system.dart';

/// A class that contains all theme configurations for the Vietnamese billiards social networking application.
///
/// Now uses consolidated DesignTokens and AppColors from design_system
class AppTheme {
  AppTheme._();

  // Modern Billiards Color Palette - Now using AppColors from design_system
  static const Color primaryLight = AppColors.primary; // Modern teal green
  static const Color primaryVariantLight = Color(
    0xFF004D40,
  ); // Deeper supportive green
  static const Color secondaryLight = Color(0xFF26A69A); // Vibrant accent
  static const Color secondaryVariantLight = Color(0xFF4DB6AC); // Light success
  static const Color backgroundLight = Color(
    0xFFF8FFFE,
  ); // Ultra clean white with teal hint
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white
  static const Color errorLight = Color(0xFFE53E3E); // Modern red
  static const Color accentLight = Color(
    0xFFFF8A50,
  ); // Warm orange for highlights
  static const Color warningLight = Color(0xFFFFB020); // Modern amber
  static const Color successLight = Color(0xFF38A169); // Fresh success green
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onBackgroundLight = Color(0xFF212121); // Text primary
  static const Color onSurfaceLight = Color(0xFF212121);
  static const Color onErrorLight = Color(0xFFFFFFFF);

  static const Color primaryDark = Color(
    0xFF2E7D32,
  ); // Lighter green for dark mode
  static const Color primaryVariantDark = Color(0xFF1B5E20); // Darker variant
  static const Color secondaryDark = Color(0xFF388E3C); // Secondary in dark
  static const Color secondaryVariantDark = Color(
    0xFF4CAF50,
  ); // Lighter variant
  static const Color backgroundDark = Color(0xFF121212); // Dark background
  static const Color surfaceDark = Color(0xFF1E1E1E); // Dark surface
  static const Color errorDark = Color(0xFFCF6679); // Dark error
  static const Color accentDark = Color(0xFFFF8F00); // Lighter accent for dark
  static const Color warningDark = Color(0xFFFFB74D); // Lighter warning
  static const Color successDark = Color(0xFF66BB6A); // Lighter success
  static const Color onPrimaryDark = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF000000);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF000000);

  // Card and dialog colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2D2D2D);
  static const Color dialogLight = Color(0xFFFFFFFF);
  static const Color dialogDark = Color(0xFF2D2D2D);

  // Shadow colors - minimal elevation
  static const Color shadowLight = Color(0x0A000000); // Very subtle
  static const Color shadowDark = Color(0x0AFFFFFF);

  // Divider colors - subtle borders
  static const Color dividerLight = Color(0x1F000000);
  static const Color dividerDark = Color(0x1FFFFFFF);

  // Text colors with proper hierarchy
  static const Color textPrimaryLight = Color(0xFF212121); // High contrast
  static const Color textSecondaryLight = Color(0xFF757575); // Supporting text
  static const Color textDisabledLight = Color(0x61000000); // 38% opacity

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xB3FFFFFF); // 70% opacity
  static const Color textDisabledDark = Color(0x61FFFFFF); // 38% opacity

  /// Light theme optimized for Vietnamese billiards social networking
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      primaryContainer: primaryVariantLight,
      onPrimaryContainer: onPrimaryLight,
      secondary: secondaryLight,
      onSecondary: onSecondaryLight,
      secondaryContainer: secondaryVariantLight,
      onSecondaryContainer: onSecondaryLight,
      tertiary: accentLight,
      onTertiary: onPrimaryLight,
      tertiaryContainer: warningLight,
      onTertiaryContainer: onPrimaryLight,
      error: errorLight,
      onError: onErrorLight,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      onSurfaceVariant: textSecondaryLight,
      outline: dividerLight,
      outlineVariant: Color(0x1F757575),
      shadow: shadowLight,
      scrim: shadowLight,
      inverseSurface: surfaceDark,
      onInverseSurface: onSurfaceDark,
      inversePrimary: primaryDark,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: cardLight,
    dividerColor: dividerLight,

    // AppBar theme - iOS style (flat) on iOS, Material on Android
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceLight,
      foregroundColor: textPrimaryLight,
      elevation: (!kIsWeb && Platform.isIOS) ? 0.0 : 1.0, // iOS: flat, Android: minimal elevation
      shadowColor: shadowLight,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: (!kIsWeb && Platform.isIOS)
          ? TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textPrimaryLight,
              letterSpacing: -0.3, // iOS negative spacing
            )
          : GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: textPrimaryLight,
              letterSpacing: 0.15,
            ),
      iconTheme: IconThemeData(color: textPrimaryLight),
      actionsIconTheme: IconThemeData(color: textPrimaryLight),
    ),

    // Card theme - iOS style (16px radius, subtle shadow) on iOS
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: (!kIsWeb && Platform.isIOS) ? 0.0 : DesignTokens.elevation2, // iOS: flat
      shadowColor: shadowLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          (!kIsWeb && Platform.isIOS) ? 16.0 : 12.0, // iOS: 16px, Android: 12px
        ),
      ),
      margin: DesignTokens.only(
        left: DesignTokens.space16,
        right: DesignTokens.space16,
        top: DesignTokens.space8,
        bottom: DesignTokens.space8,
      ),
    ),

    // Bottom navigation for main app navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primaryLight,
      unselectedItemColor: textSecondaryLight,
      elevation: 8.0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Floating action button for challenge creation
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentLight,
      foregroundColor: onPrimaryLight,
      elevation: DesignTokens.elevation4,
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.radius(DesignTokens.radiusLG),
      ),
    ),

    // Button themes - iOS style (flat, 12px radius) on iOS
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimaryLight,
        backgroundColor: primaryLight, // Brand teal green #1E8A6F
        elevation: (!kIsWeb && Platform.isIOS) ? 0.0 : DesignTokens.elevation2, // iOS: flat
        padding: DesignTokens.only(
          left: DesignTokens.space24,
          right: DesignTokens.space24,
          top: DesignTokens.space12,
          bottom: DesignTokens.space12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            (!kIsWeb && Platform.isIOS) ? 12.0 : 8.0, // iOS: 12px, Android: 8px
          ),
        ),
        textStyle: (!kIsWeb && Platform.isIOS)
            ? TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3, // iOS negative spacing
              )
            : GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: DesignTokens.letterSpacingWide,
              ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight, // Brand teal green
        padding: DesignTokens.only(
          left: DesignTokens.space24,
          right: DesignTokens.space24,
          top: DesignTokens.space12,
          bottom: DesignTokens.space12,
        ),
        side: BorderSide(
          color: primaryLight,
          width: (!kIsWeb && Platform.isIOS) ? 1.0 : 1.5, // iOS: thinner border
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            (!kIsWeb && Platform.isIOS) ? 12.0 : 8.0, // iOS: 12px
          ),
        ),
        textStyle: (!kIsWeb && Platform.isIOS)
            ? TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              )
            : GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: DesignTokens.letterSpacingWide,
              ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: (!kIsWeb && Platform.isIOS) 
            ? const Color(0xFF007AFF) // iOS blue cho links
            : primaryLight, // Brand color cho Android
        padding: DesignTokens.only(
          left: DesignTokens.space16,
          right: DesignTokens.space16,
          top: DesignTokens.space8,
          bottom: DesignTokens.space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            (!kIsWeb && Platform.isIOS) ? 12.0 : 8.0, // iOS: 12px
          ),
        ),
        textStyle: (!kIsWeb && Platform.isIOS)
            ? TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.3,
              )
            : GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: DesignTokens.letterSpacingWide,
              ),
      ),
    ),

    // Text theme with Vietnamese character support
    textTheme: _buildTextTheme(isLight: true),

    // Input decoration - iOS style (rounded, no border) on iOS
    inputDecorationTheme: InputDecorationTheme(
      fillColor: (!kIsWeb && Platform.isIOS) 
          ? const Color(0xFFF2F2F7) // iOS gray background
          : surfaceLight,
      filled: true,
      contentPadding: DesignTokens.only(
        left: DesignTokens.space16,
        right: DesignTokens.space16,
        top: DesignTokens.space12,
        bottom: DesignTokens.space12,
      ),
      border: (!kIsWeb && Platform.isIOS)
          ? InputBorder.none // iOS: no border
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: dividerLight, width: 1),
            ),
      enabledBorder: (!kIsWeb && Platform.isIOS)
          ? InputBorder.none // iOS: no border
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: dividerLight, width: 1),
            ),
      focusedBorder: (!kIsWeb && Platform.isIOS)
          ? InputBorder.none // iOS: no border, just background change
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: primaryLight, width: 2),
            ),
      errorBorder: OutlineInputBorder(
        borderRadius: DesignTokens.radius(DesignTokens.radiusSM),
        borderSide: const BorderSide(color: errorLight, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: DesignTokens.radius(DesignTokens.radiusSM),
        borderSide: const BorderSide(color: errorLight, width: 2),
      ),
      labelStyle: GoogleFonts.openSans(
        color: textSecondaryLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.openSans(
        color: textDisabledLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Interactive elements
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return Colors.grey[300];
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight.withValues(alpha: 0.5);
        }
        return Colors.grey[400];
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(onPrimaryLight),
      side: const BorderSide(color: dividerLight, width: 2),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return textSecondaryLight;
      }),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryLight,
      linearTrackColor: dividerLight,
      circularTrackColor: dividerLight,
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: primaryLight,
      thumbColor: primaryLight,
      overlayColor: primaryLight.withValues(alpha: 0.2),
      inactiveTrackColor: dividerLight,
    ),

    // Tab bar for tournament brackets
    tabBarTheme: TabBarThemeData(
      labelColor: primaryLight,
      unselectedLabelColor: textSecondaryLight,
      indicatorColor: primaryLight,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimaryLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: GoogleFonts.openSans(color: surfaceLight, fontSize: 12),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimaryLight,
      contentTextStyle: GoogleFonts.openSans(color: surfaceLight, fontSize: 14),
      actionTextColor: accentLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),

    // Bottom sheet for challenge creation
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceLight,
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
    ),

    // Expansion tile for tournament brackets
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: surfaceLight,
      collapsedBackgroundColor: surfaceLight,
      textColor: textPrimaryLight,
      collapsedTextColor: textPrimaryLight,
      iconColor: textSecondaryLight,
      collapsedIconColor: textSecondaryLight,
    ),
    dialogTheme: DialogThemeData(backgroundColor: dialogLight),
  );

  /// Dark theme optimized for low-light billiards venues
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      primaryContainer: primaryVariantDark,
      onPrimaryContainer: onPrimaryDark,
      secondary: secondaryDark,
      onSecondary: onSecondaryDark,
      secondaryContainer: secondaryVariantDark,
      onSecondaryContainer: onSecondaryDark,
      tertiary: accentDark,
      onTertiary: onPrimaryDark,
      tertiaryContainer: warningDark,
      onTertiaryContainer: onPrimaryDark,
      error: errorDark,
      onError: onErrorDark,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      onSurfaceVariant: textSecondaryDark,
      outline: dividerDark,
      outlineVariant: Color(0x1fb3ffffff),
      shadow: shadowDark,
      scrim: shadowDark,
      inverseSurface: surfaceLight,
      onInverseSurface: onSurfaceLight,
      inversePrimary: primaryLight,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: cardDark,
    dividerColor: dividerDark,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: textPrimaryDark,
      elevation: 1.0,
      shadowColor: shadowDark,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: textPrimaryDark,
        letterSpacing: 0.15,
      ),
      iconTheme: IconThemeData(color: textPrimaryDark),
      actionsIconTheme: IconThemeData(color: textPrimaryDark),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 2.0,
      shadowColor: shadowDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryDark,
      unselectedItemColor: textSecondaryDark,
      elevation: 8.0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentDark,
      foregroundColor: onPrimaryDark,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimaryDark,
        backgroundColor: primaryDark,
        elevation: 2.0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: const BorderSide(color: primaryDark, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
    ),
    textTheme: _buildTextTheme(isLight: false),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceDark,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: dividerDark, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: dividerDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: errorDark, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: errorDark, width: 2),
      ),
      labelStyle: GoogleFonts.openSans(
        color: textSecondaryDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.openSans(
        color: textDisabledDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return Colors.grey[600];
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark.withValues(alpha: 0.5);
        }
        return Colors.grey[700];
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(onPrimaryDark),
      side: const BorderSide(color: dividerDark, width: 2),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return textSecondaryDark;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryDark,
      linearTrackColor: dividerDark,
      circularTrackColor: dividerDark,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryDark,
      thumbColor: primaryDark,
      overlayColor: primaryDark.withValues(alpha: 0.2),
      inactiveTrackColor: dividerDark,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: primaryDark,
      unselectedLabelColor: textSecondaryDark,
      indicatorColor: primaryDark,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: textPrimaryDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: GoogleFonts.openSans(color: surfaceDark, fontSize: 12),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimaryDark,
      contentTextStyle: GoogleFonts.openSans(color: surfaceDark, fontSize: 14),
      actionTextColor: accentDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceDark,
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: surfaceDark,
      collapsedBackgroundColor: surfaceDark,
      textColor: textPrimaryDark,
      collapsedTextColor: textPrimaryDark,
      iconColor: textSecondaryDark,
      collapsedIconColor: textSecondaryDark,
    ),
    dialogTheme: DialogThemeData(backgroundColor: dialogDark),
  );

  /// Helper method to build text theme with Vietnamese character support
  /// iOS Support: Uses SF Pro Display on iOS with negative letter spacing
  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textPrimary = isLight ? textPrimaryLight : textPrimaryDark;
    final Color textSecondary = isLight
        ? textSecondaryLight
        : textSecondaryDark;
    final Color textDisabled = isLight ? textDisabledLight : textDisabledDark;
    
    final isIOS = !kIsWeb && Platform.isIOS;
    final fontFamily = isIOS ? '.SF Pro Display' : null; // iOS system font
    final letterSpacing = isIOS ? -0.3 : 0.0; // iOS negative spacing

    return TextTheme(
      // Display styles for tournament headers - MONTSERRAT BOLD
      displayLarge: GoogleFonts.montserrat(
        fontSize: 57,
        fontWeight: FontWeight.w800, // Extra bold for impact
        color: textPrimary,
        letterSpacing: -1.0, // Tighter for modern look
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.25,
      ),

      // Headline styles for section headers - MONTSERRAT STRONG
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.25,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0,
      ),

      // Title styles for cards and dialogs - INTER CLEAN
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.1,
      ),

      // Body styles - iOS SF Pro on iOS, Source Sans 3 on Android
      bodyLarge: isIOS
          ? TextStyle(
              fontFamily: fontFamily,
              fontSize: 17, // iOS standard body size
              fontWeight: FontWeight.w400,
              color: textPrimary,
              letterSpacing: letterSpacing,
              height: 1.2, // iOS tighter line height
            )
          : GoogleFonts.sourceSans3(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: textPrimary,
              letterSpacing: 0.1,
              height: 1.6,
            ),
      bodyMedium: isIOS
          ? TextStyle(
              fontFamily: fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: textPrimary,
              letterSpacing: letterSpacing,
              height: 1.2,
            )
          : GoogleFonts.sourceSans3(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textPrimary,
              letterSpacing: 0.1,
              height: 1.5,
            ),
      bodySmall: isIOS
          ? TextStyle(
              fontFamily: fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textSecondary,
              letterSpacing: letterSpacing,
              height: 1.2,
            )
          : GoogleFonts.sourceSans3(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: textSecondary,
              letterSpacing: 0.1,
              height: 1.4,
            ),

      // Label styles for buttons and captions - ROBOTO UI
      labelLarge: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textDisabled,
        letterSpacing: 0.5,
      ),
    );
  }
}
