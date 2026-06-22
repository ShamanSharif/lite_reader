import 'package:equatable/equatable.dart';

/// A user-authored note anchored to a position in a book.
///
/// [quotedText] is the optional passage the note refers to (also the source for
/// generating a shareable quotation image). [locator] is format-agnostic: a PDF
/// page number as string, or an EPUB CFI.
class Note extends Equatable {
  const Note({
    required this.id,
    required this.bookId,
    required this.content,
    required this.createdAt,
    this.locator,
    this.quotedText,
  });

  final String id;
  final String bookId;
  final String content;
  final String? locator;
  final String? quotedText;
  final DateTime createdAt;

  Note copyWith({String? content, String? quotedText}) => Note(
    id: id,
    bookId: bookId,
    content: content ?? this.content,
    createdAt: createdAt,
    locator: locator,
    quotedText: quotedText ?? this.quotedText,
  );

  @override
  List<Object?> get props => [id, bookId, content, quotedText, locator];
}
