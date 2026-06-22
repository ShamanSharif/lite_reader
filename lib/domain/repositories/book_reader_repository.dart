import '../entities/book.dart';
import '../entities/bookmark.dart';
import '../entities/note.dart';
import '../entities/reading_progress.dart';

/// The single contract the presentation layer depends on for everything about
/// books on the shelf. The data layer provides the concrete implementation,
/// so swapping Hive for SQLite/Isar later requires zero presentation changes.
///
/// File ingestion (picking + copying bytes into app storage) is intentionally
/// kept out of this contract and lives in a dedicated service, because it is a
/// platform/IO concern rather than a persistence concern. The repository only
/// receives an already-imported [Book] to persist.
abstract interface class BookReaderRepository {
  // ---- Library --------------------------------------------------------------

  /// All books currently on the shelf, newest activity first.
  Future<List<Book>> getLibrary();

  /// Reactive view of the shelf for live UI updates after imports/deletes.
  Stream<List<Book>> watchLibrary();

  Future<Book?> getBook(String id);

  /// Looks a book up by its on-disk copy path. Used by the scanner to avoid
  /// importing the same file twice.
  Future<Book?> getBookByFilePath(String filePath);

  /// Source paths of every imported book, so the scanner can skip duplicates
  /// cheaply without loading full records.
  Future<Set<String>> getKnownSourcePaths();

  /// Persists a freshly imported (and already copied-to-disk) book.
  Future<void> addBook(Book book);

  Future<void> updateBook(Book book);

  /// Removes the book record. The implementation is responsible for also
  /// deleting the copied file + cover and any progress/bookmarks.
  Future<void> deleteBook(String id);

  /// Stamps [Book.lastOpened] = now, used to power the "Continue reading" rail.
  Future<void> markOpened(String id);

  // ---- Progress -------------------------------------------------------------

  Future<ReadingProgress?> getProgress(String bookId);

  Future<void> saveProgress(ReadingProgress progress);

  // ---- Bookmarks ------------------------------------------------------------

  Future<List<Bookmark>> getBookmarks(String bookId);

  Future<void> addBookmark(Bookmark bookmark);

  Future<void> removeBookmark(String bookmarkId);

  // ---- Notes ----------------------------------------------------------------

  Future<List<Note>> getNotes(String bookId);

  Future<void> addNote(Note note);

  Future<void> updateNote(Note note);

  Future<void> removeNote(String noteId);
}
