import 'package:flutter/material.dart';

class ArtbeatColors {
  // Primary Colors
  static const Color primaryPurple = Color(0xFF8C52FF);
  static const Color primaryGreen = Color(0xFF00BF63);
  static const Color secondaryTeal = Color(0xFF00BFA5);
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Primary color getter (defaults to primaryPurple)
  static const Color primary = primaryPurple;

  // Accent Colors
  static const Color accent1 = Color(0xFF6C63FF);
  static const Color accent2 = Color(0xFF00BFA5);
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color primaryBlue = Color(0xFF007BFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textWhite = Color.fromARGB(255, 26, 4, 43);
  static const Color textDisabled = Color(0xFFADB5BD);

  // Header Colors
  static const Color headerText = Colors.white; // White for headers

  // Gray Colors
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF666666);

  // Background Colors
  static const Color backgroundPrimary = Colors.white;
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Button Colors
  static const Color buttonPrimary = primaryPurple;
  static const Color buttonSecondary = primaryGreen;
  static const Color buttonDisabled = Color(0xFFDDDDDD);

  // Status Colors
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);
  static const Color verified = Color(0xFF007BFF);
  static const Color featured = Color(0xFFFFD700);
  static const Color premium = Color(0xFFB8860B);

  // Social Colors
  static const Color like = Color(0xFFE91E63);
  static const Color comment = Color(0xFF03A9F4);
  static const Color share = Color(0xFF4CAF50);

  // Borders and Dividers
  static const Color border = Color(0xFFDEE2E6);
  static const Color divider = Color(0xFFE9ECEF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryGreen],
  );
}
