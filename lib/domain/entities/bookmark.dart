import 'package:equatable/equatable.dart';

/// A user-saved location within a book. The [locator] is format-agnostic at
/// this layer: PDF stores the page number as a string, EPUB stores a CFI.
class Bookmark extends Equatable {
  const Bookmark({
    required this.id,
    required this.bookId,
    required this.locator,
    required this.createdAt,
    this.label,
    this.previewText,
  });

  final String id;
  final String bookId;
  final String locator;
  final String? label;
  final String? previewText;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, bookId, locator];
}
