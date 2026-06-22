import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/enums/reader_enums.dart';
import '../../domain/entities/reader_settings.dart';
import '../blocs/reader_settings/reader_settings_cubit.dart';

/// Bottom sheet that edits the global [ReaderSettings] live. Reads/writes the
/// [ReaderSettingsCubit] directly so every change is persisted immediately.
class ReaderSettingsPanel extends StatelessWidget {
  const ReaderSettingsPanel({super.key});

  /// Convenience launcher used by the reader app bar.
  static Future<void> show(BuildContext context) {
    final cubit = context.read<ReaderSettingsCubit>();
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const ReaderSettingsPanel()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderSettingsCubit, ReaderSettings>(
      builder: (context, settings) {
        final cubit = context.read<ReaderSettingsCubit>();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reading theme',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ReaderThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ReaderThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ReaderThemeMode.sepia,
                    label: Text('Sepia'),
                    icon: Icon(Icons.menu_book),
                  ),
                  ButtonSegment(
                    value: ReaderThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => cubit.setThemeMode(s.first),
              ),
              const SizedBox(height: 20),
              _SliderRow(
                label: 'Font size',
                value: settings.fontScale,
                min: AppConstants.minFontScale,
                max: AppConstants.maxFontScale,
                display: '${(settings.fontScale * 100).round()}%',
                onChanged: cubit.setFontScale,
              ),
              _SliderRow(
                label: 'Line spacing',
                value: settings.lineHeight,
                min: AppConstants.minLineHeight,
                max: AppConstants.maxLineHeight,
                display: settings.lineHeight.toStringAsFixed(1),
                onChanged: cubit.setLineHeight,
              ),
              const SizedBox(height: 12),
              const Text(
                'Orientation',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ReaderOrientation>(
                segments: const [
                  ButtonSegment(
                    value: ReaderOrientation.auto,
                    label: Text('Auto'),
                    icon: Icon(Icons.screen_rotation),
                  ),
                  ButtonSegment(
                    value: ReaderOrientation.portrait,
                    label: Text('Portrait'),
                    icon: Icon(Icons.stay_current_portrait),
                  ),
                  ButtonSegment(
                    value: ReaderOrientation.landscape,
                    label: Text('Landscape'),
                    icon: Icon(Icons.stay_current_landscape),
                  ),
                ],
                selected: {settings.orientation},
                onSelectionChanged: (s) => cubit.setOrientation(s.first),
              ),
              const SizedBox(height: 20),
              const Text(
                'Page mode',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ReadingMode>(
                segments: const [
                  ButtonSegment(
                    value: ReadingMode.continuousScroll,
                    label: Text('Scroll'),
                    icon: Icon(Icons.swap_vert),
                  ),
                  ButtonSegment(
                    value: ReadingMode.paginated,
                    label: Text('Page'),
                    icon: Icon(Icons.menu_book),
                  ),
                ],
                selected: {settings.readingMode},
                onSelectionChanged: (s) => cubit.setReadingMode(s.first),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(display),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
