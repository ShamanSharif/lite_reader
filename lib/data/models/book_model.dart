import '../../core/enums/book_format.dart';
import '../../domain/entities/book.dart';

/// Serialization adapter for [Book]. We persist plain `Map`s in Hive instead of
/// generating `TypeAdapter`s — this avoids a build_runner dependency and keeps
/// the stored format human-debuggable and easy to migrate.
extension BookMapper on Book {
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'author': author,
    'filePath': filePath,
    'sourcePath': sourcePath,
    'format': format.name,
    'coverPath': coverPath,
    'fileSizeBytes': fileSizeBytes,
    'dateAdded': dateAdded.toIso8601String(),
    'lastOpened': lastOpened?.toIso8601String(),
  };
}

Book bookFromMap(Map<dynamic, dynamic> map) {
  return Book(
    id: map['id'] as String,
    title: (map['title'] as String?) ?? 'Untitled',
    author: map['author'] as String?,
    filePath: map['filePath'] as String,
    sourcePath: map['sourcePath'] as String?,
    format: BookFormat.values.byName(map['format'] as String),
    coverPath: map['coverPath'] as String?,
    fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt(),
    dateAdded: DateTime.parse(map['dateAdded'] as String),
    lastOpened: map['lastOpened'] == null
        ? null
        : DateTime.parse(map['lastOpened'] as String),
  );
}
