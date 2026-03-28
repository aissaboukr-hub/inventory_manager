import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Thème Material 3 complet pour l'application
class AppTheme {
  // Material 3: Couleurs de référence
  static const Color _seedColor = Color(0xFF6750A4); // Violet Material 3
  
  // Material 3: Rayons de bordure standard
  static const double _radiusSmall = 8.0;
  static const double _radiusMedium = 12.0;
  static const double _radiusLarge = 16.0;
  static const double _radiusXLarge = 28.0;

  /// Thème clair Material 3
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,

      // Material 3: Couleurs de surface
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,

      // Material 3: AppBar
      appBarTheme: _buildAppBarTheme(colorScheme),

      // Material 3: Cards
      cardTheme: _buildCardTheme(colorScheme),

      // Material 3: Boutons
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
      filledButtonThemeData: _buildFilledButtonThemeData(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),

      // Material 3: FAB
      floatingActionButtonTheme: _buildFabTheme(),

      // Material 3: Input
      inputDecorationTheme: _buildInputTheme(colorScheme),

      // Material 3: Dialogs
      dialogTheme: _buildDialogTheme(colorScheme),

      // Material 3: SnackBar
      snackBarTheme: _buildSnackBarTheme(colorScheme),

      // Material 3: Chips
      chipTheme: _buildChipTheme(colorScheme),

      // Material 3: Navigation
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      navigationRailTheme: _buildNavigationRailTheme(colorScheme),

      // Material 3: Divider & List
      dividerTheme: _buildDividerTheme(colorScheme),
      listTileTheme: _buildListTileTheme(),

      // Material 3: Switch, Checkbox, Radio
      switchTheme: _buildSwitchTheme(colorScheme),
      checkboxTheme: _buildCheckboxTheme(colorScheme),
      radioTheme: _buildRadioTheme(colorScheme),

      // Material 3: Typography
      textTheme: _buildTextTheme(colorScheme),

      // Material 3: Icones
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),

      // Material 3: Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceVariant,
        circularTrackColor: colorScheme.surfaceVariant,
      ),

      // Material 3: Sliders
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceVariant,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.12),
      ),

      // Material 3: Tabs
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
      ),

      // Material 3: Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radiusXLarge)),
        ),
      ),

      // Material 3: Menu
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: MaterialStatePropertyAll(colorScheme.surface),
          surfaceTintColor: MaterialStatePropertyAll(colorScheme.surfaceTint),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusMedium)),
          ),
        ),
      ),

      // Material 3: Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(_radiusSmall),
        ),
        textStyle: TextStyle(color: colorScheme.onInverseSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Material 3: Banner
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
      ),
    );
  }

  /// Thème sombre Material 3
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      
      appBarTheme: _buildAppBarTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
      filledButtonThemeData: _buildFilledButtonThemeData(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      floatingActionButtonTheme: _buildFabTheme(),
      inputDecorationTheme: _buildInputTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      navigationRailTheme: _buildNavigationRailTheme(colorScheme),
      dividerTheme: _buildDividerTheme(colorScheme),
      listTileTheme: _buildListTileTheme(),
      switchTheme: _buildSwitchTheme(colorScheme),
      checkboxTheme: _buildCheckboxTheme(colorScheme),
      radioTheme: _buildRadioTheme(colorScheme),
      textTheme: _buildTextTheme(colorScheme),
      
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceVariant,
        circularTrackColor: colorScheme.surfaceVariant,
      ),
      
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceVariant,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.12),
      ),
      
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
      ),
      
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_radiusXLarge)),
        ),
      ),
      
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: MaterialStatePropertyAll(colorScheme.surface),
          surfaceTintColor: MaterialStatePropertyAll(colorScheme.surfaceTint),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusMedium)),
          ),
        ),
      ),
      
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(_radiusSmall),
        ),
        textStyle: TextStyle(color: colorScheme.onInverseSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
      ),
    );
  }

  // ==================== BUILDERS DE THÈMES ====================

  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 4,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: 
            colorScheme.brightness == Brightness.light 
                ? Brightness.dark 
                : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            colorScheme.brightness == Brightness.light 
                ? Brightness.dark 
                : Brightness.light,
      ),
    );
  }

  static CardTheme _buildCardTheme(ColorScheme colorScheme) {
    return CardTheme(
      elevation: 1,
      surfaceTintColor: colorScheme.surfaceTint,
      color: colorScheme.surface,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(64, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(ColorScheme colorScheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(64, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static ButtonStyle _buildFilledButtonThemeData(ColorScheme colorScheme) {
    return FilledButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      minimumSize: const Size(64, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(64, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        minimumSize: const Size(48, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSmall),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme() {
    return FloatingActionButtonThemeData(
      elevation: 3,
      highlightElevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusLarge),
      ),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  static InputDecorationTheme _buildInputTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      
      // Border par défaut
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusSmall),
        borderSide: BorderSide.none,
      ),
      
      // Border enabled
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusSmall),
        borderSide: BorderSide.none,
      ),
      
      // Border focused
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusSmall),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      
      // Border error
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusSmall),
        borderSide: BorderSide(color: colorScheme.error, width: 1),
      ),
      
      // Border focused error
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusSmall),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      
      // Border disabled
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusSmall),
        borderSide: BorderSide.none,
      ),
      
      // Labels
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      
      floatingLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      
      // Hint
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      
      // Error
      errorStyle: TextStyle(
        color: colorScheme.error,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      
      // Icônes
      prefixIconColor: colorScheme.onSurfaceVariant,
      suffixIconColor: colorScheme.onSurfaceVariant,
      
      // Dense pour compacité
      isDense: false,
    );
  }

  static DialogTheme _buildDialogTheme(ColorScheme colorScheme) {
    return DialogTheme(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusXLarge),
      ),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w400,
      ),
      contentTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      iconColor: colorScheme.secondary,
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: colorScheme.onInverseSurface,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: colorScheme.inversePrimary,
      elevation: 6,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusSmall),
      ),
      width: 344,
      insetPadding: const EdgeInsets.all(16),
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceVariant,
      deleteIconColor: colorScheme.onSurfaceVariant,
      disabledColor: colorScheme.onSurface.withOpacity(0.12),
      selectedColor: colorScheme.secondaryContainer,
      secondarySelectedColor: colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: TextStyle(
        color: colorScheme.onSecondaryContainer,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusSmall),
      ),
      side: BorderSide.none,
      elevation: 0,
      pressElevation: 0,
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme(ColorScheme colorScheme) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 3,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
      ),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return TextStyle(
            color: colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }
        return TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return IconThemeData(
            color: colorScheme.onSecondaryContainer,
            size: 24,
          );
        }
        return IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 24,
        );
      }),
    );
  }

  static NavigationRailThemeData _buildNavigationRailTheme(ColorScheme colorScheme) {
    return NavigationRailThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      selectedIconTheme: IconThemeData(
        color: colorScheme.onSecondaryContainer,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
      ),
    );
  }

  static DividerThemeData _buildDividerTheme(ColorScheme colorScheme) {
    return DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
      indent: 0,
      endIndent: 0,
    );
  }

  static ListTileThemeData _buildListTileTheme() {
    return ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minLeadingWidth: 24,
      minVerticalPadding: 8,
    );
  }

  static SwitchThemeData _buildSwitchTheme(ColorScheme colorScheme) {
    return SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.onPrimary;
        }
        return colorScheme.outline;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.surfaceVariant;
      }),
      trackOutlineColor: MaterialStatePropertyAll(colorScheme.outline),
    );
  }

  static CheckboxThemeData _buildCheckboxTheme(ColorScheme colorScheme) {
    return CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.primary;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStatePropertyAll(colorScheme.onPrimary),
      side: BorderSide(color: colorScheme.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  static RadioThemeData _buildRadioTheme(ColorScheme colorScheme) {
    return RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.onSurfaceVariant;
      }),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.22,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.33,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.43,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurface,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        height: 1.45,
      ),
    );
  }
}