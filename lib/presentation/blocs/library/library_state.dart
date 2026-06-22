part of 'library_cubit.dart';

enum LibraryStatus { initial, loading, ready, scanning, error }

/// Snapshot of the shelf. Derived getters split the list by format so the UI
/// can render PDF / EPUB sections without re-filtering inline.
class LibraryState extends Equatable {
  const LibraryState({
    this.status = LibraryStatus.initial,
    this.books = const [],
    this.errorMessage,
  });

  final LibraryStatus status;
  final List<Book> books;
  final String? errorMessage;

  List<Book> get pdfBooks =>
      books.where((b) => b.format == BookFormat.pdf).toList();

  List<Book> get epubBooks =>
      books.where((b) => b.format == BookFormat.epub).toList();

  /// Most recently opened book for the "Continue reading" entry point.
  Book? get lastRead {
    final opened = books.where((b) => b.lastOpened != null).toList()
      ..sort((a, b) => b.lastOpened!.compareTo(a.lastOpened!));
    return opened.isEmpty ? null : opened.first;
  }

  LibraryState copyWith({
    LibraryStatus? status,
    List<Book>? books,
    String? errorMessage,
  }) {
    return LibraryState(
      status: status ?? this.status,
      books: books ?? this.books,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, books, errorMessage];
}
