import 'package:equatable/equatable.dart';

import '../../core/enums/book_format.dart';

/// A book as the domain cares about it: an identity, where its bytes live on
/// disk, and lightweight metadata for the shelf. Rendering details (pages,
/// chapters) deliberately live elsewhere ([ReadingProgress]).
class Book extends Equatable {
  const Book({
    required this.id,
    required this.title,
    required this.filePath,
    required this.format,
    required this.dateAdded,
    this.author,
    this.coverPath,
    this.fileSizeBytes,
    this.lastOpened,
    this.sourcePath,
  });

  final String id;
  final String title;
  final String? author;

  /// Absolute path to the app-private copy of the file.
  final String filePath;

  /// Original location the file was imported from (picker selection or a
  /// scanned folder). Used by the scanner to avoid re-importing duplicates.
  final String? sourcePath;
  final BookFormat format;
  final String? coverPath;
  final int? fileSizeBytes;
  final DateTime dateAdded;
  final DateTime? lastOpened;

  Book copyWith({
    String? title,
    String? author,
    String? coverPath,
    DateTime? lastOpened,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath,
      format: format,
      coverPath: coverPath ?? this.coverPath,
      fileSizeBytes: fileSizeBytes,
      dateAdded: dateAdded,
      lastOpened: lastOpened ?? this.lastOpened,
      sourcePath: sourcePath,
    );
  }

  @override
  List<Object?> get props => [id, filePath, format, lastOpened];
}
