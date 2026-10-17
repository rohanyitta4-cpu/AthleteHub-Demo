import 'package:flutter/material.dart';

/// Responsive layout utility for handling different screen sizes across iOS and Android
class ResponsiveLayout {
  final BuildContext context;
  
  ResponsiveLayout(this.context);
  
  // Get screen dimensions
  Size get screenSize => MediaQuery.of(context).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  
  // Get safe area insets (handles notches, status bars, etc.)
  EdgeInsets get safeAreaInsets => MediaQuery.of(context).padding;
  double get safeAreaTop => safeAreaInsets.top;
  double get safeAreaBottom => safeAreaInsets.bottom;
  double get safeAreaLeft => safeAreaInsets.left;
  double get safeAreaRight => safeAreaInsets.right;
  
  // Get available height (excluding safe areas)
  double get availableHeight => screenHeight - safeAreaTop - safeAreaBottom;
  
  // Device type detection
  bool get isSmallPhone => screenWidth < 375; // iPhone SE, smaller Android phones
  bool get isMediumPhone => screenWidth >= 375 && screenWidth < 414; // iPhone 12/13/14
  bool get isLargePhone => screenWidth >= 414 && screenWidth < 768; // iPhone Pro Max, larger Android
  bool get isTablet => screenWidth >= 768;
  
  // Platform detection
  bool get isIOS => Theme.of(context).platform == TargetPlatform.iOS;
  bool get isAndroid => Theme.of(context).platform == TargetPlatform.android;
  
  // Responsive spacing
  double get defaultPadding => isSmallPhone ? 12.0 : isMediumPhone ? 16.0 : 20.0;
  double get cardPadding => isSmallPhone ? 10.0 : isMediumPhone ? 12.0 : 16.0;
  double get sectionSpacing => isSmallPhone ? 16.0 : isMediumPhone ? 20.0 : 24.0;
  
  // Responsive font sizes
  double getScaleFactor() {
    if (isSmallPhone) return 0.9;
    if (isMediumPhone) return 1.0;
    if (isLargePhone) return 1.05;
    return 1.1; // Tablet
  }
  
  double scaleFont(double baseSize) => baseSize * getScaleFactor();
  
  // Responsive grid columns
  int getGridColumns({int? minColumns, int? maxColumns}) {
    if (isTablet) return maxColumns ?? 4;
    if (isLargePhone) return 3;
    if (isMediumPhone) return 2;
    return minColumns ?? 1; // Small phone
  }
  
  // Calculate responsive aspect ratio for GridView
  double calculateAspectRatio({
    required int crossAxisCount,
    required double cardHeight,
    double? minHeight,
    double? maxHeight,
  }) {
    final effectiveWidth = (screenWidth - (defaultPadding * 2) - 
                           ((crossAxisCount - 1) * 16)) / crossAxisCount;
    
    final effectiveHeight = cardHeight.clamp(
      minHeight ?? 80.0,
      maxHeight ?? double.infinity,
    );
    
    return effectiveWidth / effectiveHeight;
  }
  
  // Safe container height (accounts for keyboard, safe areas, etc.)
  double getSafeContainerHeight({
    required double preferredHeight,
    double? maxHeight,
    double? minHeight,
  }) {
    final available = availableHeight;
    final height = preferredHeight.clamp(
      minHeight ?? 100.0,
      maxHeight ?? available * 0.9,
    );
    return height;
  }
  
  // Check if keyboard is visible
  bool get isKeyboardVisible {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return viewInsets.bottom > 0;
  }
  
  // Get keyboard height
  double get keyboardHeight => MediaQuery.of(context).viewInsets.bottom;
}

/// Extension for easy access
extension ResponsiveLayoutExtension on BuildContext {
  ResponsiveLayout get responsive => ResponsiveLayout(this);
}

