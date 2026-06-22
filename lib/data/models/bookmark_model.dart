import '../../domain/entities/bookmark.dart';

extension BookmarkMapper on Bookmark {
  Map<String, dynamic> toMap() => {
    'id': id,
    'bookId': bookId,
    'locator': locator,
    'label': label,
    'previewText': previewText,
    'createdAt': createdAt.toIso8601String(),
  };
}

Bookmark bookmarkFromMap(Map<dynamic, dynamic> map) {
  return Bookmark(
    id: map['id'] as String,
    bookId: map['bookId'] as String,
    locator: map['locator'] as String,
    label: map['label'] as String?,
    previewText: map['previewText'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}
