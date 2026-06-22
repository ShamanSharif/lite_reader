import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../domain/entities/library_settings.dart';

/// Persists the user's scan-folder configuration across launches.
class LibrarySettingsCubit extends HydratedCubit<LibrarySettings> {
  LibrarySettingsCubit() : super(const LibrarySettings());

  void addScanFolder(String path) => emit(state.addFolder(path));

  void removeScanFolder(String path) => emit(state.removeFolder(path));

  @override
  LibrarySettings? fromJson(Map<String, dynamic> json) {
    try {
      final folders =
          (json['scanFolders'] as List?)?.cast<String>() ?? const [];
      return LibrarySettings(scanFolders: folders);
    } catch (_) {
      return const LibrarySettings();
    }
  }

  @override
  Map<String, dynamic>? toJson(LibrarySettings state) => {
    'scanFolders': state.scanFolders,
  };
}
