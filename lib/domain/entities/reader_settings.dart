import 'package:equatable/equatable.dart';

import '../../core/constants/app_constants.dart';
import '../../core/enums/reader_enums.dart';

/// Global, user-controlled reading preferences. Persisted via HydratedBloc so
/// the choices survive restarts. Pure value object — no Flutter imports — so it
/// stays in the domain layer.
class ReaderSettings extends Equatable {
  const ReaderSettings({
    this.themeMode = ReaderThemeMode.light,
    this.fontScale = 1.0,
    this.lineHeight = 1.4,
    this.orientation = ReaderOrientation.auto,
    this.readingMode = ReadingMode.continuousScroll,
  });

  final ReaderThemeMode themeMode;

  /// Multiplier applied to the EPUB base font size (PDF zoom is handled by the
  /// PDF engine separately).
  final double fontScale;
  final double lineHeight;
  final ReaderOrientation orientation;
  final ReadingMode readingMode;

  ReaderSettings copyWith({
    ReaderThemeMode? themeMode,
    double? fontScale,
    double? lineHeight,
    ReaderOrientation? orientation,
    ReadingMode? readingMode,
  }) {
    return ReaderSettings(
      themeMode: themeMode ?? this.themeMode,
      fontScale: (fontScale ?? this.fontScale).clamp(
        AppConstants.minFontScale,
        AppConstants.maxFontScale,
      ),
      lineHeight: (lineHeight ?? this.lineHeight).clamp(
        AppConstants.minLineHeight,
        AppConstants.maxLineHeight,
      ),
      orientation: orientation ?? this.orientation,
      readingMode: readingMode ?? this.readingMode,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    fontScale,
    lineHeight,
    orientation,
    readingMode,
  ];
}
