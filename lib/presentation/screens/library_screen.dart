import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/book_format.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/book_reader_repository.dart';
import '../blocs/library/library_cubit.dart';
import '../blocs/library_settings/library_settings_cubit.dart';
import '../widgets/book_grid_card.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';

/// Tablet-aware shelf:
///  * Phones / small tablets: a responsive grid; tapping a book opens it.
///  * Large tablets: a master–detail layout (grid on the left, a rich detail
///    pane on the right) so the extra width feels purpose-built.
///
/// A format filter (All / EPUB / PDF) categorizes the shelf, and the app bar
/// exposes folder-scan and settings actions.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  BookFormat? _filter; // null = all
  String? _selectedId;

  List<Book> _applyFilter(List<Book> books) => _filter == null
      ? books
      : books.where((b) => b.format == _filter).toList();

  Future<void> _import(BuildContext context) async {
    final book = await context.read<LibraryCubit>().importBook();
    if (book != null && context.mounted) _open(context, book);
  }

  Future<void> _quickScan(BuildContext context) async {
    final folders = context.read<LibrarySettingsCubit>().state.scanFolders;
    final messenger = ScaffoldMessenger.of(context);
    if (folders.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add a scan folder in Settings first.')),
      );
      return;
    }
    final report = await context.read<LibraryCubit>().scanFolders(folders);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          report.permissionDenied
              ? 'Storage permission denied.'
              : 'Imported ${report.imported} new book(s).',
        ),
      ),
    );
  }

  void _open(BuildContext context, Book book) {
    Navigator.of(context).push(ReaderScreen.route(book));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        actions: [
          IconButton(
            tooltip: 'Scan folders',
            icon: const Icon(Icons.youtube_searched_for),
            onPressed: () => _quickScan(context),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(SettingsScreen.route()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _import(context),
        icon: const Icon(Icons.add),
        label: const Text('Add book'),
      ),
      body: BlocConsumer<LibraryCubit, LibraryState>(
        listenWhen: (prev, curr) =>
            curr.status == LibraryStatus.error && curr.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          if (state.status == LibraryStatus.loading ||
              state.status == LibraryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.books.isEmpty) return const _EmptyShelf();

          final books = _applyFilter(state.books);
          final isLargeTablet = Responsive.isLargeTablet(context);

          final shelf = _Shelf(
            books: books,
            filter: _filter,
            onFilterChanged: (f) => setState(() => _filter = f),
            selectedId: isLargeTablet ? _selectedId : null,
            onBookTap: (book) {
              if (isLargeTablet) {
                setState(() => _selectedId = book.id);
              } else {
                _open(context, book);
              }
            },
          );

          if (!isLargeTablet) return shelf;

          final selected = books.firstWhere(
            (b) => b.id == _selectedId,
            orElse: () => books.isNotEmpty ? books.first : state.books.first,
          );
          return Row(
            children: [
              Expanded(flex: 3, child: shelf),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: _DetailPane(
                  book: _selectedId == null ? null : selected,
                  onRead: (book) => _open(context, book),
                  onDelete: (book) {
                    context.read<LibraryCubit>().deleteBook(book.id);
                    setState(() => _selectedId = null);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.books,
    required this.filter,
    required this.onFilterChanged,
    required this.onBookTap,
    this.selectedId,
  });

  final List<Book> books;
  final BookFormat? filter;
  final ValueChanged<BookFormat?> onFilterChanged;
  final ValueChanged<Book> onBookTap;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.libraryColumns(context);
    return Column(
      children: [
        _FilterBar(filter: filter, onChanged: onFilterChanged),
        Expanded(
          child: books.isEmpty
              ? const Center(child: Text('No books in this category'))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: columns == 1 ? 2.6 : 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, i) => BookGridCard(
                    book: books[i],
                    selected: books[i].id == selectedId,
                    onTap: () => onBookTap(books[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onChanged});

  final BookFormat? filter;
  final ValueChanged<BookFormat?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: filter == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('EPUB'),
            selected: filter == BookFormat.epub,
            onSelected: (_) => onChanged(BookFormat.epub),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('PDF'),
            selected: filter == BookFormat.pdf,
            onSelected: (_) => onChanged(BookFormat.pdf),
          ),
        ],
      ),
    );
  }
}

class _DetailPane extends StatelessWidget {
  const _DetailPane({
    required this.book,
    required this.onRead,
    required this.onDelete,
  });

  final Book? book;
  final ValueChanged<Book> onRead;
  final ValueChanged<Book> onDelete;

  @override
  Widget build(BuildContext context) {
    final b = book;
    if (b == null) {
      return const Center(child: Text('Select a book'));
    }
    final repository = context.read<BookReaderRepository>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            b.format.isPdf ? Icons.picture_as_pdf : Icons.menu_book,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(b.title, style: Theme.of(context).textTheme.headlineSmall),
          if (b.author != null) ...[
            const SizedBox(height: 4),
            Text(b.author!, style: Theme.of(context).textTheme.titleMedium),
          ],
          const SizedBox(height: 8),
          Text('Format: ${b.format.extension.toUpperCase()}'),
          FutureBuilder<ReadingProgress?>(
            future: repository.getProgress(b.id),
            builder: (context, snapshot) {
              final pct = snapshot.data?.percentage ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  pct == 0 ? 'Not started' : '${(pct * 100).round()}% read',
                ),
              );
            },
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onRead(b),
                  icon: const Icon(Icons.menu_book),
                  label: Text(
                    b.lastOpened == null ? 'Start reading' : 'Continue',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => onDelete(b),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_stories, size: 72),
          const SizedBox(height: 12),
          Text(
            'Your shelf is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text('Tap "Add book" or scan a folder from Settings.'),
        ],
      ),
    );
  }
}
