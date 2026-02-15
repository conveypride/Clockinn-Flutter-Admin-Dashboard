import 'package:clockinn_flutter_admin/theme/clockInnColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClockInnTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ClockInnColors.bgDeepest,
    textTheme: GoogleFonts.dmSansTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.syne(
        fontSize: 32, fontWeight: FontWeight.w800,
        color: ClockInnColors.textPrimary, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.syne(
        fontSize: 26, fontWeight: FontWeight.w700,
        color: ClockInnColors.textPrimary, letterSpacing: -0.4,
      ),
      headlineLarge: GoogleFonts.syne(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: ClockInnColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.syne(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: ClockInnColors.textPrimary,
      ),
      titleLarge: GoogleFonts.syne(
        fontSize: 15, fontWeight: FontWeight.w700,
        color: ClockInnColors.textPrimary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: ClockInnColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: ClockInnColors.textSecondary,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: ClockInnColors.textSecondary,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: ClockInnColors.textMuted, letterSpacing: 1.2,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      surface:   ClockInnColors.bgDark,
      primary:   ClockInnColors.green400,
      secondary: ClockInnColors.green300,
      error:     ClockInnColors.red,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: ClockInnColors.bgDark,
      elevation: 0,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ClockInnColors.bgDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black45,
      scrolledUnderElevation: 1,
      titleTextStyle: GoogleFonts.syne(
        fontSize: 17, fontWeight: FontWeight.w700,
        color: ClockInnColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: ClockInnColors.textSecondary),
    ),
  );
}
