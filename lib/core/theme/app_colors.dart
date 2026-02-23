import 'package:flutter/material.dart';

/// App Color Palette - Warm Coffee Cafe Theme
class AppColors {
  AppColors._();

  // Primary Colors - Warm Tan/Brown (buttons, chips, accents)
  static const Color primary = Color(0xFFC8A97E); // Warm Tan
  static const Color primaryLight = Color(0xFFDEC5A0); // Light Tan
  static const Color primaryDark = Color(0xFFA0845A); // Dark Tan
  static const Color primaryGradientStart = Color(0xFFD4B48A);
  static const Color primaryGradientEnd = Color(0xFFC8A97E);

  // Accent Colors - Dark Coffee Brown (text emphasis, dark buttons)
  static const Color accent = Color(0xFF5D4037); // Coffee Brown
  static const Color accentLight = Color(0xFF8D6E63); // Light Brown
  static const Color accentDark = Color(0xFF3E2723); // Dark Espresso
  static const Color accentGradientStart = Color(0xFF6D4C41);
  static const Color accentGradientEnd = Color(0xFF5D4037);

  // Neutral Colors
  static const Color background = Color(0xFFFFF8F0); // Warm Cream
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceVariant = Color(0xFFF5EFE6); // Light Beige

  // Text Colors
  static const Color textPrimary = Color(0xFF2C1810); // Dark Espresso
  static const Color textSecondary = Color(0xFF8B7355); // Medium Brown
  static const Color textHint = Color(0xFFC4B39A); // Muted Tan
  static const Color textOnPrimary = Color(0xFF2C1810); // Dark on light buttons
  static const Color textOnAccent = Color(0xFFFFFFFF); // White on dark buttons

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFFC107); // Amber
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue

  // Special UI Colors
  static const Color divider = Color(0xFFE8DFD3);
  static const Color shadow = Color(0x1A5D4037);
  static const Color overlay = Color(0x663E2723);
  static const Color shimmerBase = Color(0xFFE8DFD3);
  static const Color shimmerHighlight = Color(0xFFF5EFE6);

  // Glassmorphism
  static const Color glassBackground = Color(0xCCFFF8F0); // 80% cream
  static const Color glassBackgroundDark = Color(0x993E2723); // 60% dark brown

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
    colors: [Color(0xFFFFF8F0), Color(0xFFF5EFE6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [shimmerBase, shimmerHighlight, shimmerBase],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // Promo Banner Gradient
  static const LinearGradient promoBannerGradient = LinearGradient(
    colors: [Color(0xFF4A6741), Color(0xFF3D5A35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Food Category Colors
  static const Color vegColor = Color(0xFF4CAF50);
  static const Color nonVegColor = Color(0xFFE53935);
  static const Color veganColor = Color(0xFF66BB6A);

  // Rating Colors
  static const Color ratingGold = Color(0xFFFFD700);
  static const Color ratingEmpty = Color(0xFFE8DFD3);

  // Status Colors for Orders
  static const Color statusPlaced = Color(0xFF2196F3); // Blue
  static const Color statusConfirmed = Color(0xFF9C27B0); // Purple
  static const Color statusPreparing = Color(0xFFFF9800); // Orange
  static const Color statusOutForDelivery = Color(0xFF00BCD4); // Cyan
  static const Color statusDelivered = Color(0xFF4CAF50); // Green
  static const Color statusCancelled = Color(0xFFF44336); // Red
}
