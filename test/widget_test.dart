// Unit tests for the pure-Dart domain + data-mapping layers. These avoid any
// platform plugin so they run fast on CI without an emulator.

import 'package:flutter_test/flutter_test.dart';

import 'package:lite_reader/core/enums/book_format.dart';
import 'package:lite_reader/core/enums/reader_enums.dart';
import 'package:lite_reader/data/models/book_model.dart';
import 'package:lite_reader/data/models/note_model.dart';
import 'package:lite_reader/domain/entities/book.dart';
import 'package:lite_reader/domain/entities/library_settings.dart';
import 'package:lite_reader/domain/entities/note.dart';
import 'package:lite_reader/domain/entities/reader_settings.dart';

void main() {
  group('BookFormat.fromPath', () {
    test('detects pdf and epub case-insensitively', () {
      expect(BookFormat.fromPath('/a/B.PDF'), BookFormat.pdf);
      expect(BookFormat.fromPath('book.epub'), BookFormat.epub);
    });

    test('returns null for unsupported types', () {
      expect(BookFormat.fromPath('note.txt'), isNull);
      expect(BookFormat.fromPath('no_extension'), isNull);
    });
  });

  group('ReaderSettings', () {
    test('clamps font scale and line height within bounds', () {
      const settings = ReaderSettings();
      expect(
        settings.copyWith(fontScale: 99).fontScale,
        lessThanOrEqualTo(2.2),
      );
      expect(
        settings.copyWith(fontScale: 0).fontScale,
        greaterThanOrEqualTo(0.7),
      );
      expect(
        settings.copyWith(lineHeight: 99).lineHeight,
        lessThanOrEqualTo(2.4),
      );
    });

    test('copyWith preserves untouched fields', () {
      const settings = ReaderSettings(themeMode: ReaderThemeMode.sepia);
      final updated = settings.copyWith(fontScale: 1.5);
      expect(updated.themeMode, ReaderThemeMode.sepia);
      expect(updated.fontScale, 1.5);
    });
  });

  group('Book serialization round-trip', () {
    test('toMap -> fromMap preserves fields', () {
      final book = Book(
        id: 'abc',
        title: 'Test Book',
        author: 'Jane',
        filePath: '/books/abc.epub',
        sourcePath: '/sdcard/Books/abc.epub',
        format: BookFormat.epub,
        dateAdded: DateTime.parse('2024-01-01T00:00:00.000'),
      );

      final restored = bookFromMap(book.toMap());

      expect(restored.id, book.id);
      expect(restored.title, book.title);
      expect(restored.author, book.author);
      expect(restored.sourcePath, book.sourcePath);
      expect(restored.format, BookFormat.epub);
      expect(restored.dateAdded, book.dateAdded);
    });
  });

  group('Note serialization round-trip', () {
    test('toMap -> fromMap preserves fields', () {
      final note = Note(
        id: 'n1',
        bookId: 'abc',
        content: 'Great passage',
        quotedText: 'To be or not to be',
        locator: 'epubcfi(/6/4)',
        createdAt: DateTime.parse('2024-02-02T10:00:00.000'),
      );

      final restored = noteFromMap(note.toMap());

      expect(restored.content, note.content);
      expect(restored.quotedText, note.quotedText);
      expect(restored.locator, note.locator);
    });
  });

  group('LibrarySettings', () {
    test('addFolder dedups and removeFolder works', () {
      const initial = LibrarySettings();
      final added = initial.addFolder('/a').addFolder('/b').addFolder('/a');
      expect(added.scanFolders, ['/a', '/b']);
      expect(added.removeFolder('/a').scanFolders, ['/b']);
    });
  });

  group('ReadingMode setting', () {
    test('copyWith updates reading mode', () {
      const settings = ReaderSettings();
      expect(settings.readingMode, ReadingMode.continuousScroll);
      expect(
        settings.copyWith(readingMode: ReadingMode.paginated).readingMode,
        ReadingMode.paginated,
      );
    });
  });
}
