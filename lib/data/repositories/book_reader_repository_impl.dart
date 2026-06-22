import '../../domain/entities/book.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/book_reader_repository.dart';
import '../datasources/local_book_datasource.dart';
import '../services/file_ingestion_service.dart';

/// Hive-backed implementation of [BookReaderRepository].
///
/// It coordinates two collaborators:
///  * [LocalBookDataSource] for persistence.
///  * [FileIngestionService] for on-disk file cleanup when books are deleted.
class BookReaderRepositoryImpl implements BookReaderRepository {
  BookReaderRepositoryImpl({
    required LocalBookDataSource dataSource,
    required FileIngestionService ingestionService,
  }) : _local = dataSource,
       _ingestion = ingestionService;

  final LocalBookDataSource _local;
  final FileIngestionService _ingestion;

  @override
  Future<List<Book>> getLibrary() async => _local.readAllBooks();

  @override
  Stream<List<Book>> watchLibrary() => _local.watchBooks();

  @override
  Future<Book?> getBook(String id) async => _local.readBook(id);

  @override
  Future<Book?> getBookByFilePath(String filePath) async =>
      _local.readBookByFilePath(filePath);

  @override
  Future<Set<String>> getKnownSourcePaths() async =>
      _local.readKnownSourcePaths();

  @override
  Future<void> addBook(Book book) => _local.writeBook(book);

  @override
  Future<void> updateBook(Book book) => _local.writeBook(book);

  @override
  Future<void> deleteBook(String id) async {
    final book = _local.readBook(id);
    await _local.deleteBook(id);
    if (book != null) await _ingestion.deleteFiles(book);
  }

  @override
  Future<void> markOpened(String id) async {
    final book = _local.readBook(id);
    if (book == null) return;
    await _local.writeBook(book.copyWith(lastOpened: DateTime.now()));
  }

  @override
  Future<ReadingProgress?> getProgress(String bookId) async =>
      _local.readProgress(bookId);

  @override
  Future<void> saveProgress(ReadingProgress progress) =>
      _local.writeProgress(progress);

  @override
  Future<List<Bookmark>> getBookmarks(String bookId) async =>
      _local.readBookmarks(bookId);

  @override
  Future<void> addBookmark(Bookmark bookmark) => _local.writeBookmark(bookmark);

  @override
  Future<void> removeBookmark(String bookmarkId) =>
      _local.deleteBookmark(bookmarkId);

  @override
  Future<List<Note>> getNotes(String bookId) async => _local.readNotes(bookId);

  @override
  Future<void> addNote(Note note) => _local.writeNote(note);

  @override
  Future<void> updateNote(Note note) => _local.writeNote(note);

  @override
  Future<void> removeNote(String noteId) => _local.deleteNote(noteId);
}
