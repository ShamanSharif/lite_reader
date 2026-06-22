import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../core/enums/reader_enums.dart';
import '../../../domain/entities/reader_settings.dart';

/// Holds the global [ReaderSettings] and persists every change automatically.
///
/// Because it extends [HydratedCubit], the [toJson]/[fromJson] pair below is the
/// only persistence code we need — HydratedBloc rehydrates the last state on
/// launch. No manual Hive box wiring required for settings.
class ReaderSettingsCubit extends HydratedCubit<ReaderSettings> {
  ReaderSettingsCubit() : super(const ReaderSettings());

  void setThemeMode(ReaderThemeMode mode) =>
      emit(state.copyWith(themeMode: mode));

  void setFontScale(double scale) => emit(state.copyWith(fontScale: scale));

  void incrementFontScale(double delta) =>
      emit(state.copyWith(fontScale: state.fontScale + delta));

  void setLineHeight(double height) => emit(state.copyWith(lineHeight: height));

  void setOrientation(ReaderOrientation orientation) =>
      emit(state.copyWith(orientation: orientation));

  void setReadingMode(ReadingMode mode) =>
      emit(state.copyWith(readingMode: mode));

  void reset() => emit(const ReaderSettings());

  @override
  ReaderSettings? fromJson(Map<String, dynamic> json) {
    try {
      return ReaderSettings(
        themeMode: ReaderThemeMode.values.byName(
          json['themeMode'] as String? ?? ReaderThemeMode.light.name,
        ),
        fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
        lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.4,
        orientation: ReaderOrientation.values.byName(
          json['orientation'] as String? ?? ReaderOrientation.auto.name,
        ),
        readingMode: ReadingMode.values.byName(
          json['readingMode'] as String? ?? ReadingMode.continuousScroll.name,
        ),
      );
    } catch (_) {
      // Corrupt/incompatible stored state -> fall back to defaults.
      return const ReaderSettings();
    }
  }

  @override
  Map<String, dynamic>? toJson(ReaderSettings state) => {
    'themeMode': state.themeMode.name,
    'fontScale': state.fontScale,
    'lineHeight': state.lineHeight,
    'orientation': state.orientation.name,
    'readingMode': state.readingMode.name,
  };
}
