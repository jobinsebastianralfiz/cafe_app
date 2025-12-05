import 'package:flutter/material.dart';

/// App Color Palette - Fresh & Vibrant Theme
class AppColors {
  AppColors._();

  // Primary Colors - Teal/Turquoise
  static const Color primary = Color(0xFF00BFA5); // Vibrant Teal
  static const Color primaryLight = Color(0xFF5DF2D6); // Light Teal
  static const Color primaryDark = Color(0xFF008E76); // Dark Teal
  static const Color primaryGradientStart = Color(0xFF00D4B5);
  static const Color primaryGradientEnd = Color(0xFF00BFA5);

  // Accent Colors - Orange
  static const Color accent = Color(0xFFFF6B35); // Vibrant Orange
  static const Color accentLight = Color(0xFFFF9D6E); // Light Orange
  static const Color accentDark = Color(0xFFE64A19); // Dark Orange
  static const Color accentGradientStart = Color(0xFFFF7E47);
  static const Color accentGradientEnd = Color(0xFFFF6B35);

  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA); // Off-white
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceVariant = Color(0xFFF5F5F5); // Light gray

  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // Almost black
  static const Color textSecondary = Color(0xFF757575); // Medium gray
  static const Color textHint = Color(0xFFBDBDBD); // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White
  static const Color textOnAccent = Color(0xFFFFFFFF); // White

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFFC107); // Amber
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue

  // Special UI Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1F000000);
  static const Color overlay = Color(0x66000000);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Glassmorphism
  static const Color glassBackground = Color(0xCCFFFFFF); // 80% white
  static const Color glassBackgroundDark = Color(0x99000000); // 60% black

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentGradientStart, accentGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [shimmerBase, shimmerHighlight, shimmerBase],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // Food Category Colors
  static const Color vegColor = Color(0xFF4CAF50);
  static const Color nonVegColor = Color(0xFFE53935);
  static const Color veganColor = Color(0xFF66BB6A);

  // Rating Colors
  static const Color ratingGold = Color(0xFFFFD700);
  static const Color ratingEmpty = Color(0xFFE0E0E0);

  // Status Colors for Orders
  static const Color statusPlaced = Color(0xFF2196F3); // Blue
  static const Color statusConfirmed = Color(0xFF9C27B0); // Purple
  static const Color statusPreparing = Color(0xFFFF9800); // Orange
  static const Color statusOutForDelivery = Color(0xFF00BCD4); // Cyan
  static const Color statusDelivered = Color(0xFF4CAF50); // Green
  static const Color statusCancelled = Color(0xFFF44336); // Red
}
