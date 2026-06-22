import 'package:equatable/equatable.dart';

/// Persistent, app-level (non-reader) preferences.
///
/// Currently holds the folders the library scanner crawls for books. Kept
/// separate from [ReaderSettings] because its lifecycle and UI live with the
/// library, not the reader.
class LibrarySettings extends Equatable {
  const LibrarySettings({this.scanFolders = const []});

  /// Absolute directory paths the user has added as scan roots.
  final List<String> scanFolders;

  LibrarySettings copyWith({List<String>? scanFolders}) =>
      LibrarySettings(scanFolders: scanFolders ?? this.scanFolders);

  LibrarySettings addFolder(String path) {
    if (scanFolders.contains(path)) return this;
    return copyWith(scanFolders: [...scanFolders, path]);
  }

  LibrarySettings removeFolder(String path) =>
      copyWith(scanFolders: scanFolders.where((f) => f != path).toList());

  @override
  List<Object?> get props => [scanFolders];
}
