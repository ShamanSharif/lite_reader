import 'package:flutter/material.dart';

import '../enums/reader_enums.dart';

/// Maps the abstract [ReaderThemeMode] onto concrete colors + a Material
/// [ThemeData]. Keeping this in one place means the library shell, the reader
/// chrome and the EPUB text layer all stay visually consistent.
class ReaderPalette {
  const ReaderPalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.accent,
    required this.brightness,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color accent;
  final Brightness brightness;

  factory ReaderPalette.of(ReaderThemeMode mode) {
    switch (mode) {
      case ReaderThemeMode.light:
        return const ReaderPalette(
          background: Color(0xFFFFFFFF),
          surface: Color(0xFFF4F4F6),
          text: Color(0xFF1A1A1A),
          accent: Color(0xFF3D5AFE),
          brightness: Brightness.light,
        );
      case ReaderThemeMode.dark:
        return const ReaderPalette(
          background: Color(0xFF121212),
          surface: Color(0xFF1E1E1E),
          text: Color(0xFFE6E6E6),
          accent: Color(0xFF8C9EFF),
          brightness: Brightness.dark,
        );
      case ReaderThemeMode.sepia:
        return const ReaderPalette(
          background: Color(0xFFF4ECD8),
          surface: Color(0xFFEDE3C8),
          text: Color(0xFF5B4636),
          accent: Color(0xFF8A6D3B),
          brightness: Brightness.light,
        );
    }
  }

  ThemeData toThemeData() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(surface: surface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
      ),
    );
  }
}
