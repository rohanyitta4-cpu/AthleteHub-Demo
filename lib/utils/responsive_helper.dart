import 'package:flutter/material.dart';

/// Comprehensive responsive design utility for the entire app
/// Use this instead of fixed dimensions throughout the app
class ResponsiveHelper {
  final BuildContext context;
  
  ResponsiveHelper(this.context);
  
  // Screen dimensions
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  
  // Breakpoints
  static const double smallPhone = 360;    // iPhone SE, small Android
  static const double mediumPhone = 375;   // iPhone X/11/12/13
  static const double largePhone = 414;    // iPhone Plus/Max
  static const double tablet = 768;        // iPad, tablet
  
  // Device type detection
  bool get isSmallPhone => screenWidth < mediumPhone;
  bool get isMediumPhone => screenWidth >= mediumPhone && screenWidth < largePhone;
  bool get isLargePhone => screenWidth >= largePhone && screenWidth < tablet;
  bool get isTablet => screenWidth >= tablet;
  
  // Scaling factor based on screen size
  double get scaleFactor {
    if (isSmallPhone) return 0.85;
    if (isMediumPhone) return 1.0;
    if (isLargePhone) return 1.1;
    if (isTablet) return 1.2;
    return 1.0;
  }
  
  // Responsive sizing methods
  double scale(double value) => value * scaleFactor;
  
  // Common responsive values
  double get defaultPadding => scale(16.0);
  double get smallPadding => scale(8.0);
  double get mediumPadding => scale(12.0);
  double get largePadding => scale(24.0);
  double get extraLargePadding => scale(32.0);
  
  // Responsive font sizes
  double get fontSizeSmall => scale(12.0);
  double get fontSizeBody => scale(14.0);
  double get fontSizeMedium => scale(16.0);
  double get fontSizeLarge => scale(20.0);
  double get fontSizeXLarge => scale(24.0);
  double get fontSizeXXLarge => scale(32.0);
  
  // Responsive icon sizes
  double get iconSizeSmall => scale(16.0);
  double get iconSizeMedium => scale(24.0);
  double get iconSizeLarge => scale(32.0);
  
  // Responsive spacing
  double get spacingXSmall => scale(4.0);
  double get spacingSmall => scale(8.0);
  double get spacingMedium => scale(16.0);
  double get spacingLarge => scale(24.0);
  double get spacingXLarge => scale(32.0);
  
  // Responsive button sizes
  double get buttonHeight => scale(48.0);
  double get buttonHeightSmall => scale(40.0);
  double get buttonHeightLarge => scale(56.0);
  
  // Responsive card sizes
  double get cardPadding => scale(16.0);
  double get cardBorderRadius => scale(12.0);
  
  // Grid aspect ratios
  double get gridAspectRatio {
    if (isSmallPhone) return 1.8;
    if (isMediumPhone) return 2.0;
    if (isLargePhone) return 2.2;
    if (isTablet) return 2.5;
    return 2.0;
  }
  
  // Chart heights
  double get chartHeight {
    if (isSmallPhone) return scale(200.0);
    if (isMediumPhone) return scale(240.0);
    if (isLargePhone) return scale(280.0);
    if (isTablet) return scale(320.0);
    return scale(260.0);
  }
  
  // Input field heights
  double get inputHeight => scale(48.0);
  
  // App bar height
  double get appBarHeight => scale(56.0);
  
  // Bottom navigation height
  double get bottomNavHeight => scale(60.0);
  
  // Max content width (for tablets/desktop)
  double get maxContentWidth {
    if (isTablet) return 600.0;
    return screenWidth;
  }
  
  // Edge insets helpers
  EdgeInsets get paddingAll => EdgeInsets.all(defaultPadding);
  EdgeInsets get paddingHorizontal => EdgeInsets.symmetric(horizontal: defaultPadding);
  EdgeInsets get paddingVertical => EdgeInsets.symmetric(vertical: defaultPadding);
  EdgeInsets get paddingSmall => EdgeInsets.all(smallPadding);
  EdgeInsets get paddingLarge => EdgeInsets.all(largePadding);
  
  // Safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(context).padding;
  
  // Keyboard aware padding
  EdgeInsets get keyboardAwarePadding {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return EdgeInsets.only(bottom: keyboardHeight);
  }
}

