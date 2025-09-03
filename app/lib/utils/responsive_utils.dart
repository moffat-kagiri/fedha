import 'package:flutter/material.dart';

/// Utility class for responsive UI adjustments
class ResponsiveUtils {
  /// Check if the current device is a tablet based on screen width
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > 600;
  }

  /// Check if the current device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape;
  }

  /// Get appropriate font size based on device type
  static double getFontSize(BuildContext context, double base) {
    return isTablet(context) ? base * 1.3 : base;
  }

  /// Get appropriate padding based on device type
  static EdgeInsets getPadding(BuildContext context, {double basePadding = 16.0}) {
    return EdgeInsets.all(isTablet(context) ? basePadding * 1.5 : basePadding);
  }

  /// Get appropriate icon size based on device type
  static double getIconSize(BuildContext context, double base) {
    return isTablet(context) ? base * 1.3 : base;
  }
}
