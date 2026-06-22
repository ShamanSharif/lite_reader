import '../../domain/entities/reading_progress.dart';

extension ReadingProgressMapper on ReadingProgress {
  Map<String, dynamic> toMap() => {
    'bookId': bookId,
    'percentage': percentage,
    'updatedAt': updatedAt.toIso8601String(),
    'pdfPage': pdfPage,
    'epubCfi': epubCfi,
    'epubParagraphIndex': epubParagraphIndex,
  };
}

ReadingProgress readingProgressFromMap(Map<dynamic, dynamic> map) {
  return ReadingProgress(
    bookId: map['bookId'] as String,
    percentage: (map['percentage'] as num?)?.toDouble() ?? 0,
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    pdfPage: (map['pdfPage'] as num?)?.toInt(),
    epubCfi: map['epubCfi'] as String?,
    epubParagraphIndex: (map['epubParagraphIndex'] as num?)?.toInt(),
  );
}
