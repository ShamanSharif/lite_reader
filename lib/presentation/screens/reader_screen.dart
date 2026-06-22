import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/book_format.dart';
import '../../core/enums/reader_enums.dart';
import '../../core/theme/reader_palette.dart';
import '../../core/utils/responsive.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/reader_settings.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/book_reader_repository.dart';
import '../blocs/reader_settings/reader_settings_cubit.dart';
import '../widgets/epub_reader_view.dart';
import '../widgets/pdf_reader_view.dart';
import '../widgets/quote_image_composer.dart';
import '../widgets/reader_nav_drawer.dart';
import '../widgets/reader_settings_panel.dart';

/// Single entry point for reading any book. It loads the saved
/// [ReadingProgress], applies the orientation lock, and **conditionally swaps
/// the rendering engine** based on [Book.format]. It also hosts the navigation
/// drawer (TOC / bookmarks / notes), page jump, and quotation-image entry.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book});

  final Book book;

  static Route<void> route(Book book) =>
      MaterialPageRoute(builder: (_) => ReaderScreen(book: book));

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pdfViewKey = GlobalKey<PdfReaderViewState>();
  final _epubViewKey = GlobalKey<EpubReaderViewState>();

  late final BookReaderRepository _repository;
  late Future<ReadingProgress> _initialProgress;

  // Live, in-memory position. Flushed to disk on changes + on dispose.
  int _pdfPage = 1;
  int _pdfTotalPages = 0;
  String? _epubCfi;
  double _percentage = 0;

  bool get _isPdf => widget.book.format.isPdf;
  bool get _isEpub => widget.book.format.isEpub;

  @override
  void initState() {
    super.initState();
    _repository = context.read<BookReaderRepository>();
    _repository.markOpened(widget.book.id);
    _initialProgress = _loadProgress();
  }

  Future<ReadingProgress> _loadProgress() async {
    final saved =
        await _repository.getProgress(widget.book.id) ??
        ReadingProgress.initial(widget.book.id);
    _pdfPage = saved.pdfPage ?? 1;
    _epubCfi = saved.epubCfi;
    _percentage = saved.percentage;
    return saved;
  }

  void _applyOrientation(ReaderOrientation orientation) {
    SystemChrome.setPreferredOrientations(switch (orientation) {
      ReaderOrientation.portrait => [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      ReaderOrientation.landscape => [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      ReaderOrientation.auto => DeviceOrientation.values,
    });
  }

  Future<void> _persist() {
    return _repository.saveProgress(
      ReadingProgress(
        bookId: widget.book.id,
        percentage: _percentage,
        updatedAt: DateTime.now(),
        pdfPage: _isPdf ? _pdfPage : null,
        epubCfi: _isEpub ? _epubCfi : null,
      ),
    );
  }

  // ---- Navigation callbacks shared with the drawer --------------------------

  String? _currentLocator() => _isPdf ? '$_pdfPage' : _epubCfi;

  String? _currentQuote() => null; // selection capture is a roadmap item

  void _jumpToLocator(String locator) {
    if (_isPdf) {
      final page = int.tryParse(locator);
      if (page != null) _pdfViewKey.currentState?.jumpToPage(page);
    } else {
      _epubViewKey.currentState?.gotoCfi(locator);
    }
  }

  void _openChapter(int paragraphIndex) =>
      _epubViewKey.currentState?.scrollToIndex(paragraphIndex);

  List<EpubChapterRef> _chapters() => _isEpub
      ? (_epubViewKey.currentState?.tableOfContents() ?? const [])
      : const [];

  void _createQuoteImage(String quote) {
    Navigator.of(
      context,
    ).push(QuoteImageComposer.route(book: widget.book, quote: quote));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _persist();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderSettingsCubit, ReaderSettings>(
      builder: (context, settings) {
        _applyOrientation(settings.orientation);
        final palette = ReaderPalette.of(settings.themeMode);

        return Theme(
          data: palette.toThemeData(),
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: palette.background,
            endDrawer: ReaderNavDrawer(
              book: widget.book,
              chaptersProvider: _chapters,
              currentLocator: _currentLocator,
              currentQuote: _currentQuote,
              onJumpToLocator: _jumpToLocator,
              onOpenChapter: _openChapter,
              onCreateQuoteImage: _createQuoteImage,
            ),
            appBar: AppBar(
              title: Text(widget.book.title, overflow: TextOverflow.ellipsis),
              actions: [
                if (_isPdf)
                  IconButton(
                    tooltip: 'Jump to page',
                    icon: const Icon(Icons.find_in_page_outlined),
                    onPressed: _showJumpToPageDialog,
                  ),
                IconButton(
                  tooltip: 'Reading settings',
                  icon: const Icon(Icons.tune),
                  onPressed: () => ReaderSettingsPanel.show(context),
                ),
                IconButton(
                  tooltip: 'Contents, bookmarks & notes',
                  icon: const Icon(Icons.menu_book),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
              ],
            ),
            body: FutureBuilder<ReadingProgress>(
              future: _initialProgress,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildEngine(settings, palette);
              },
            ),
          ),
        );
      },
    );
  }

  /// The conditional engine switch — the heart of the unified reader.
  Widget _buildEngine(ReaderSettings settings, ReaderPalette palette) {
    switch (widget.book.format) {
      case BookFormat.pdf:
        return PdfReaderView(
          key: _pdfViewKey,
          filePath: widget.book.filePath,
          initialPage: _pdfPage,
          paginated: settings.readingMode == ReadingMode.paginated,
          onTotalPages: (total) => _pdfTotalPages = total,
          onPageChanged: (page) {
            _pdfPage = page;
            if (_pdfTotalPages > 0) _percentage = page / _pdfTotalPages;
            _persist();
          },
        );
      case BookFormat.epub:
        // Constrain the text column on tablets so lines stay comfortable.
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Responsive.readingColumnMaxWidth,
            ),
            child: EpubReaderView(
              key: _epubViewKey,
              filePath: widget.book.filePath,
              initialCfi: _epubCfi,
              palette: palette,
              fontScale: settings.fontScale,
              lineHeight: settings.lineHeight,
              onLocationChanged: (cfi, percentage) {
                _epubCfi = cfi;
                _percentage = (percentage / 100).clamp(0.0, 1.0);
                _persist();
              },
            ),
          ),
        );
    }
  }

  Future<void> _showJumpToPageDialog() async {
    final controller = TextEditingController(text: '$_pdfPage');
    final page = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _pdfTotalPages > 0 ? '1 – $_pdfTotalPages' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Go'),
          ),
        ],
      ),
    );
    if (page != null) _pdfViewKey.currentState?.jumpToPage(page);
  }
}
