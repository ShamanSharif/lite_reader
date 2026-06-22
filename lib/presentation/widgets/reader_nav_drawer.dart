import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/book.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/book_reader_repository.dart';
import 'epub_reader_view.dart';

/// End drawer for in-book navigation. Three tabs:
///  * Contents  — EPUB table of contents (hidden for PDF).
///  * Bookmarks — saved locations, tap to jump, swipe to delete.
///  * Notes     — user notes; each can spawn a quotation image.
///
/// All bookmark/note persistence is handled here against the repository; the
/// reader screen only supplies the current locator and navigation callbacks.
class ReaderNavDrawer extends StatefulWidget {
  const ReaderNavDrawer({
    super.key,
    required this.book,
    required this.chaptersProvider,
    required this.currentLocator,
    required this.currentQuote,
    required this.onJumpToLocator,
    required this.onOpenChapter,
    required this.onCreateQuoteImage,
  });

  final Book book;

  /// Returns the EPUB chapters; empty for PDFs (Contents tab is then hidden).
  /// A provider (not a captured list) so the TOC reflects the loaded document
  /// even though it parses asynchronously after the reader opens.
  final List<EpubChapterRef> Function() chaptersProvider;

  /// Returns the current position as a storable locator string.
  final String? Function() currentLocator;

  /// Best-effort current passage text, used to pre-fill notes / quote images.
  final String? Function() currentQuote;

  final void Function(String locator) onJumpToLocator;
  final void Function(int paragraphIndex) onOpenChapter;
  final void Function(String quote) onCreateQuoteImage;

  @override
  State<ReaderNavDrawer> createState() => _ReaderNavDrawerState();
}

class _ReaderNavDrawerState extends State<ReaderNavDrawer> {
  final _uuid = const Uuid();
  late final BookReaderRepository _repository;

  List<Bookmark> _bookmarks = [];
  List<Note> _notes = [];
  bool _loading = true;

  late final List<EpubChapterRef> _chapters = widget.chaptersProvider();
  bool get _hasToc => _chapters.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _repository = context.read<BookReaderRepository>();
    _reload();
  }

  Future<void> _reload() async {
    final bookmarks = await _repository.getBookmarks(widget.book.id);
    final notes = await _repository.getNotes(widget.book.id);
    if (!mounted) return;
    setState(() {
      _bookmarks = bookmarks;
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _addBookmark() async {
    final locator = widget.currentLocator();
    if (locator == null) return;
    await _repository.addBookmark(
      Bookmark(
        id: _uuid.v4(),
        bookId: widget.book.id,
        locator: locator,
        previewText: widget.currentQuote(),
        createdAt: DateTime.now(),
      ),
    );
    await _reload();
  }

  Future<void> _composeNote() async {
    final result = await showModalBottomSheet<_NoteDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NoteEditor(initialQuote: widget.currentQuote()),
    );
    if (result == null) return;
    await _repository.addNote(
      Note(
        id: _uuid.v4(),
        bookId: widget.book.id,
        content: result.content,
        quotedText: result.quote,
        locator: widget.currentLocator(),
        createdAt: DateTime.now(),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final tabCount = _hasToc ? 3 : 2;
    return Drawer(
      child: DefaultTabController(
        length: tabCount,
        child: SafeArea(
          child: Column(
            children: [
              TabBar(
                tabs: [
                  if (_hasToc) const Tab(text: 'Contents'),
                  const Tab(text: 'Bookmarks'),
                  const Tab(text: 'Notes'),
                ],
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          if (_hasToc) _buildContents(),
                          _buildBookmarks(),
                          _buildNotes(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContents() {
    return ListView.builder(
      itemCount: _chapters.length,
      itemBuilder: (context, i) {
        final chapter = _chapters[i];
        return ListTile(
          dense: true,
          title: Text(
            chapter.title.isEmpty ? 'Chapter ${i + 1}' : chapter.title,
          ),
          onTap: () {
            widget.onOpenChapter(chapter.startIndex);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildBookmarks() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.bookmark_add),
          title: const Text('Bookmark current position'),
          onTap: _addBookmark,
        ),
        const Divider(height: 1),
        Expanded(
          child: _bookmarks.isEmpty
              ? const _EmptyHint('No bookmarks yet')
              : ListView.builder(
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, i) {
                    final b = _bookmarks[i];
                    return Dismissible(
                      key: ValueKey(b.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) async {
                        await _repository.removeBookmark(b.id);
                        await _reload();
                      },
                      background: Container(color: Colors.red.shade400),
                      child: ListTile(
                        leading: const Icon(Icons.bookmark),
                        title: Text(b.label ?? 'Bookmark ${i + 1}'),
                        subtitle: b.previewText != null
                            ? Text(
                                b.previewText!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () {
                          widget.onJumpToLocator(b.locator);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.note_add),
          title: const Text('Add note'),
          onTap: _composeNote,
        ),
        const Divider(height: 1),
        Expanded(
          child: _notes.isEmpty
              ? const _EmptyHint('No notes yet')
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, i) {
                    final n = _notes[i];
                    return Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) async {
                        await _repository.removeNote(n.id);
                        await _reload();
                      },
                      background: Container(color: Colors.red.shade400),
                      child: ListTile(
                        title: Text(
                          n.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: n.quotedText != null
                            ? Text(
                                '“${n.quotedText!}”',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : null,
                        trailing: n.quotedText != null
                            ? IconButton(
                                icon: const Icon(Icons.image_outlined),
                                tooltip: 'Make quote image',
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onCreateQuoteImage(n.quotedText!);
                                },
                              )
                            : null,
                        onTap: n.locator == null
                            ? null
                            : () {
                                widget.onJumpToLocator(n.locator!);
                                Navigator.pop(context);
                              },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(text, style: Theme.of(context).textTheme.bodyMedium));
}

class _NoteDraft {
  const _NoteDraft(this.content, this.quote);
  final String content;
  final String? quote;
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({this.initialQuote});
  final String? initialQuote;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _content;
  late final TextEditingController _quote;

  @override
  void initState() {
    super.initState();
    _content = TextEditingController();
    _quote = TextEditingController(text: widget.initialQuote ?? '');
  }

  @override
  void dispose() {
    _content.dispose();
    _quote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New note', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _quote,
            decoration: const InputDecoration(
              labelText: 'Quoted passage (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _content,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Your note',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              if (_content.text.trim().isEmpty) return;
              Navigator.pop(
                context,
                _NoteDraft(
                  _content.text.trim(),
                  _quote.text.trim().isEmpty ? null : _quote.text.trim(),
                ),
              );
            },
            child: const Text('Save note'),
          ),
        ],
      ),
    );
  }
}
