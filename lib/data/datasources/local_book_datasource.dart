import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/reading_progress.dart';
import '../models/book_model.dart';
import '../models/bookmark_model.dart';
import '../models/note_model.dart';
import '../models/reading_progress_model.dart';

/// Thin wrapper over the three Hive boxes. It speaks domain entities on its
/// public surface and handles all Map (de)serialization internally, so the
/// repository never touches raw Hive maps.
///
/// Hive is pure Dart (no native SQLite), which is exactly why it is safe on
/// Android API 21.
class LocalBookDataSource {
  LocalBookDataSource({
    required Box<Map> booksBox,
    required Box<Map> progressBox,
    required Box<Map> bookmarksBox,
    required Box<Map> notesBox,
  }) : _books = booksBox,
       _progress = progressBox,
       _bookmarks = bookmarksBox,
       _notes = notesBox;

  final Box<Map> _books;
  final Box<Map> _progress;
  final Box<Map> _bookmarks;
  final Box<Map> _notes;

  // ---- Books ----------------------------------------------------------------

  List<Book> readAllBooks() {
    final books = _books.values.map(bookFromMap).toList();
    books.sort((a, b) {
      final at = a.lastOpened ?? a.dateAdded;
      final bt = b.lastOpened ?? b.dateAdded;
      return bt.compareTo(at); // most recent activity first
    });
    return books;
  }

  Stream<List<Book>> watchBooks() {
    // Emit the current snapshot immediately, then on every box mutation.
    return _books.watch().map((_) => readAllBooks()).asBroadcastStream();
  }

  Book? readBook(String id) {
    final raw = _books.get(id);
    return raw == null ? null : bookFromMap(raw);
  }

  Book? readBookByFilePath(String filePath) {
    for (final raw in _books.values) {
      final book = bookFromMap(raw);
      if (book.filePath == filePath) return book;
    }
    return null;
  }

  Set<String> readKnownSourcePaths() {
    final paths = <String>{};
    for (final raw in _books.values) {
      final src = raw['sourcePath'] as String?;
      if (src != null) paths.add(src);
    }
    return paths;
  }

  Future<void> writeBook(Book book) => _books.put(book.id, book.toMap());

  Future<void> deleteBook(String id) async {
    await _books.delete(id);
    await _progress.delete(id);
    final marks = _bookmarks.values
        .map(bookmarkFromMap)
        .where((m) => m.bookId == id)
        .map((m) => m.id);
    await _bookmarks.deleteAll(marks);
    final notes = _notes.values
        .map(noteFromMap)
        .where((n) => n.bookId == id)
        .map((n) => n.id);
    await _notes.deleteAll(notes);
  }

  // ---- Progress -------------------------------------------------------------

  ReadingProgress? readProgress(String bookId) {
    final raw = _progress.get(bookId);
    return raw == null ? null : readingProgressFromMap(raw);
  }

  Future<void> writeProgress(ReadingProgress progress) =>
      _progress.put(progress.bookId, progress.toMap());

  // ---- Bookmarks ------------------------------------------------------------

  List<Bookmark> readBookmarks(String bookId) {
    final marks = _bookmarks.values
        .map(bookmarkFromMap)
        .where((m) => m.bookId == bookId)
        .toList();
    marks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return marks;
  }

  Future<void> writeBookmark(Bookmark bookmark) =>
      _bookmarks.put(bookmark.id, bookmark.toMap());

  Future<void> deleteBookmark(String id) => _bookmarks.delete(id);

  // ---- Notes ----------------------------------------------------------------

  List<Note> readNotes(String bookId) {
    final notes = _notes.values
        .map(noteFromMap)
        .where((n) => n.bookId == bookId)
        .toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  Future<void> writeNote(Note note) => _notes.put(note.id, note.toMap());

  Future<void> deleteNote(String id) => _notes.delete(id);

  /// Opens every box this data source needs. Call once during app bootstrap.
  static Future<LocalBookDataSource> open() async {
    final books = await Hive.openBox<Map>(AppConstants.booksBoxName);
    final progress = await Hive.openBox<Map>(AppConstants.progressBoxName);
    final bookmarks = await Hive.openBox<Map>(AppConstants.bookmarksBoxName);
    final notes = await Hive.openBox<Map>(AppConstants.notesBoxName);
    return LocalBookDataSource(
      booksBox: books,
      progressBox: progress,
      bookmarksBox: bookmarks,
      notesBox: notes,
    );
  }
}
