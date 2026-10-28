import 'package:flutter/material.dart';

/// Responsive helper class to handle responsive grid dimensions across
/// small phones, larger phones, tablets, and desktop devices.
class Responsive {
  /// Calculate appropriate number of grid columns based on width:
  /// - Small phones (< 500 dp): 2 columns
  /// - Large phones / phablets (500 - 750 dp): 3 columns
  /// - Tablets portrait / small laptops (750 - 1100 dp): 4 columns
  /// - Tablets landscape / large screens (> 1100 dp): 5 or 6 columns
  static int getColumnCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 500) {
      return 2;
    } else if (width < 750) {
      return 3;
    } else if (width < 1100) {
      return 4;
    } else {
      return 5;
    }
  }

  /// Grid cross axis spacing
  static double getCrossAxisSpacing(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 500) {
      return 12.0;
    } else if (width < 800) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  /// Grid main axis spacing
  static double getMainAxisSpacing(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 500) {
      return 12.0;
    } else if (width < 800) {
      return 16.0;
    } else {
      return 20.0;
    }
  }

  /// Card aspect ratio: slightly taller than wide (0.85) to accommodate
  /// clean photo display plus bottom metadata tags without clipping.
  static double getAspectRatio(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 500) {
      return 0.88;
    } else if (width < 800) {
      return 0.92;
    } else {
      return 0.95;
    }
  }

  /// Responsive page padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 500) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    } else if (width < 800) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0);
    }
  }
}
