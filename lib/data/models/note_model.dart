import '../../domain/entities/note.dart';

extension NoteMapper on Note {
  Map<String, dynamic> toMap() => {
    'id': id,
    'bookId': bookId,
    'content': content,
    'locator': locator,
    'quotedText': quotedText,
    'createdAt': createdAt.toIso8601String(),
  };
}

Note noteFromMap(Map<dynamic, dynamic> map) {
  return Note(
    id: map['id'] as String,
    bookId: map['bookId'] as String,
    content: map['content'] as String,
    locator: map['locator'] as String?,
    quotedText: map['quotedText'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}
