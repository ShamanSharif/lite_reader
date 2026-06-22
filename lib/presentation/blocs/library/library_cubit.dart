import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/enums/book_format.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/repositories/book_reader_repository.dart';
import '../../../data/services/file_ingestion_service.dart';
import '../../../data/services/library_scan_service.dart';

part 'library_state.dart';

/// Drives the shelf: loads books, subscribes to live changes, and orchestrates
/// import/delete by combining the [FileIngestionService] (IO) with the
/// [BookReaderRepository] (persistence).
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit({
    required BookReaderRepository repository,
    required FileIngestionService ingestionService,
    required LibraryScanService scanService,
  }) : _repository = repository,
       _ingestion = ingestionService,
       _scanService = scanService,
       super(const LibraryState());

  final BookReaderRepository _repository;
  final FileIngestionService _ingestion;
  final LibraryScanService _scanService;
  StreamSubscription<List<Book>>? _sub;

  /// Loads the initial snapshot, then keeps the state in sync with the box.
  Future<void> load() async {
    emit(state.copyWith(status: LibraryStatus.loading));
    try {
      final books = await _repository.getLibrary();
      emit(state.copyWith(status: LibraryStatus.ready, books: books));
      await _sub?.cancel();
      _sub = _repository.watchLibrary().listen(
        (books) => emit(state.copyWith(books: books)),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LibraryStatus.error,
          errorMessage: 'Failed to load library: $e',
        ),
      );
    }
  }

  /// Picks a file, copies it into app storage and persists it. Returns the
  /// imported [Book] on success (handy for "open immediately after import").
  Future<Book?> importBook() async {
    final result = await _ingestion.pickAndImport();
    switch (result) {
      case IngestionSuccess(:final book):
        await _repository.addBook(book);
        return book;
      case IngestionCancelled():
        return null;
      case IngestionFailure(:final message):
        emit(
          state.copyWith(status: LibraryStatus.error, errorMessage: message),
        );
        return null;
    }
  }

  Future<void> deleteBook(String id) => _repository.deleteBook(id);

  Future<void> markOpened(String id) => _repository.markOpened(id);

  /// Crawls [folders] for new books. Returns a [ScanReport] the UI can present;
  /// the live [watchLibrary] stream pushes any newly imported books into state.
  Future<ScanReport> scanFolders(List<String> folders) async {
    emit(state.copyWith(status: LibraryStatus.scanning));
    final report = await _scanService.scan(folders);
    emit(state.copyWith(status: LibraryStatus.ready));
    return report;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
