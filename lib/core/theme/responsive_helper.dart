import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveHelper {
  static void init(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
    );
  }

  // Screen size breakpoints
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 900;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isSmallScreen(context)) {
      return EdgeInsets.all(16.w);
    } else if (isMediumScreen(context)) {
      return EdgeInsets.all(24.w);
    } else {
      return EdgeInsets.all(32.w);
    }
  }

  // Responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isSmallScreen(context)) {
      return baseFontSize.sp;
    } else if (isMediumScreen(context)) {
      return (baseFontSize * 1.1).sp;
    } else {
      return (baseFontSize * 1.2).sp;
    }
  }

  // Responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    if (isSmallScreen(context)) {
      return baseIconSize.w;
    } else if (isMediumScreen(context)) {
      return (baseIconSize * 1.1).w;
    } else {
      return (baseIconSize * 1.2).w;
    }
  }

  // Responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (isSmallScreen(context)) {
      return baseSpacing.h;
    } else if (isMediumScreen(context)) {
      return (baseSpacing * 1.2).h;
    } else {
      return (baseSpacing * 1.5).h;
    }
  }

  // Safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  // Device type detection
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768;
  }

  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  // Orientation helpers
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Dynamic sizing based on screen density
  static double getAdaptiveSize(BuildContext context, double baseSize) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Base size for 375x812 (iPhone X)
    const baseWidth = 375.0;
    const baseHeight = 812.0;
    
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;
    
    // Use the smaller ratio to ensure content fits
    final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;
    
    return baseSize * ratio;
  }

  // Grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    if (isSmallScreen(context)) {
      return 1;
    } else if (isMediumScreen(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  // List item height based on screen size
  static double getListItemHeight(BuildContext context) {
    if (isSmallScreen(context)) {
      return 60.h;
    } else if (isMediumScreen(context)) {
      return 70.h;
    } else {
      return 80.h;
    }
  }
}
