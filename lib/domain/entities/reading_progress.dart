import 'package:equatable/equatable.dart';

/// The user's absolute position inside a book, persisted so reading can resume
/// seamlessly across sessions.
///
/// The format dictates which locator is meaningful:
///  * PDF  -> [pdfPage] (1-based page number).
///  * EPUB -> [epubCfi] (a canonical fragment identifier) with
///    [epubParagraphIndex] kept as a robust fallback if a CFI can't be built.
///
/// [percentage] is engine-agnostic and used by the shelf progress bar.
class ReadingProgress extends Equatable {
  const ReadingProgress({
    required this.bookId,
    required this.percentage,
    required this.updatedAt,
    this.pdfPage,
    this.epubCfi,
    this.epubParagraphIndex,
  });

  final String bookId;

  /// 0.0 – 1.0 fraction read.
  final double percentage;
  final DateTime updatedAt;

  final int? pdfPage;
  final String? epubCfi;
  final int? epubParagraphIndex;

  factory ReadingProgress.initial(String bookId) =>
      ReadingProgress(bookId: bookId, percentage: 0, updatedAt: DateTime.now());

  @override
  List<Object?> get props => [
    bookId,
    percentage,
    pdfPage,
    epubCfi,
    epubParagraphIndex,
  ];
}
