import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Responsive helper for adapting layouts between iPhone and iPad.
class ResponsiveHelper {
  /// Screen width breakpoint for tablets (iPad).
  static const double tabletBreakpoint = 600.0;

  /// Returns true if the device is a tablet (iPad) based on shortest side.
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= tabletBreakpoint;
  }

  /// Returns the screen width.
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Returns the screen height.
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Scales a value for tablet: returns [tabletValue] on iPad, [phoneValue] on iPhone.
  static double value(BuildContext context, {required double phone, required double tablet}) {
    return isTablet(context) ? tablet : phone;
  }

  /// Responsive font size scaling factor.
  static double fontScale(BuildContext context) {
    return isTablet(context) ? 1.3 : 1.0;
  }

  /// Responsive icon scale.
  static double iconScale(BuildContext context) {
    return isTablet(context) ? 1.4 : 1.0;
  }

  /// Responsive horizontal padding for content areas.
  static double contentPadding(BuildContext context) {
    return isTablet(context) ? 40.0 : 20.0;
  }

  /// Grid cross axis count for channel grids.
  static int gridColumns(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= tabletBreakpoint) return 3;
    return 2;
  }

  /// Max content width for forms/centered layouts on iPad.
  static double maxContentWidth(BuildContext context) {
    return isTablet(context) ? 600.0 : double.infinity;
  }

  /// Playlist card height.
  static double playlistCardHeight(BuildContext context) {
    return isTablet(context) ? 400.0 : 310.0;
  }

  /// Viewport fraction for PageView carousel.
  static double carouselViewportFraction(BuildContext context) {
    return isTablet(context) ? 0.65 : 0.92;
  }

  /// Hero card height for category screen.
  static double heroCardHeight(BuildContext context) {
    return isTablet(context) ? 260.0 : 190.0;
  }

  /// Split card height for category screen.
  static double splitCardHeight(BuildContext context) {
    return isTablet(context) ? 260.0 : 190.0;
  }

  /// Sets preferred orientations based on device type.
  /// On iPad: allows all orientations.
  /// On iPhone: locks to portrait only.
  static void setPortraitOrAllOrientations(BuildContext context) {
    if (isTablet(context)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  /// Sets landscape orientation (for player screens).
  /// On iPad: allows all orientations (landscape preferred but portrait allowed).
  /// On iPhone: forces landscape only.
  static void setLandscapeOrAllOrientations(BuildContext context) {
    if (isTablet(context)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }
}
