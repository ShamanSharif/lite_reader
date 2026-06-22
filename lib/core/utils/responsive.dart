import 'package:flutter/widgets.dart';

/// Device size classes used to tailor layouts. We treat anything >= 600dp wide
/// as a tablet (the conventional Material breakpoint), and >= 900dp as a large
/// tablet eligible for a persistent master–detail layout.
enum DeviceClass { phone, tablet, largeTablet }

class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 600;
  static const double largeTabletBreakpoint = 900;

  /// Maximum text column width in the reader so EPUB lines stay readable on
  /// wide tablet screens instead of stretching edge to edge.
  static const double readingColumnMaxWidth = 720;

  static DeviceClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= largeTabletBreakpoint) return DeviceClass.largeTablet;
    if (width >= tabletBreakpoint) return DeviceClass.tablet;
    return DeviceClass.phone;
  }

  static bool isTablet(BuildContext context) =>
      of(context) != DeviceClass.phone;

  static bool isLargeTablet(BuildContext context) =>
      of(context) == DeviceClass.largeTablet;

  /// Column count for the library grid based on width.
  static int libraryColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 4;
    if (width >= largeTabletBreakpoint) return 3;
    if (width >= tabletBreakpoint) return 2;
    return 1;
  }
}
