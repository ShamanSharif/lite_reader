import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// PDF rendering engine wrapper built on `pdfx`.
///
/// Two reading modes, both backed by Android's native `PdfRenderer` (API 21+):
///  * continuous scroll  -> [PdfViewPinch]: smooth vertical scroll + pinch zoom.
///  * paginated (book)    -> [PdfView]: one page per swipe, with per-page pinch
///    zoom (via photo_view) and page snapping.
///
/// The widget reports the current page upward and exposes [jumpToPage] so the
/// parent owns all progress persistence and navigation. The reading mode is a
/// live setting, so the matching controller is (re)built in [didUpdateWidget].
class PdfReaderView extends StatefulWidget {
  const PdfReaderView({
    super.key,
    required this.filePath,
    required this.initialPage,
    required this.paginated,
    required this.onPageChanged,
    this.onTotalPages,
  });

  final String filePath;

  /// 1-based starting page (resume position).
  final int initialPage;

  /// When true, render page-by-page like a physical book.
  final bool paginated;

  /// Called with the 1-based current page whenever it changes.
  final ValueChanged<int> onPageChanged;

  /// Reports total pages once the document is loaded, for percentage math.
  final ValueChanged<int>? onTotalPages;

  @override
  State<PdfReaderView> createState() => PdfReaderViewState();
}

class PdfReaderViewState extends State<PdfReaderView> {
  PdfControllerPinch? _scrollController;
  PdfController? _pageController;

  // Tracks the live page so we can preserve position across a mode switch.
  late int _lastPage;

  @override
  void initState() {
    super.initState();
    _lastPage = widget.initialPage.clamp(1, 1 << 30);
    _createController(_lastPage);
  }

  void _createController(int initialPage) {
    if (widget.paginated) {
      _pageController = PdfController(
        document: PdfDocument.openFile(widget.filePath),
        initialPage: initialPage,
      );
    } else {
      _scrollController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.filePath),
        initialPage: initialPage,
      );
    }
  }

  void _disposeControllers() {
    _scrollController?.dispose();
    _scrollController = null;
    _pageController?.dispose();
    _pageController = null;
  }

  @override
  void didUpdateWidget(PdfReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The reading mode (and thus the controller type) can change live from the
    // settings panel, and the file can change if the key is reused. Rebuild the
    // controller in either case, resuming at the current page.
    if (oldWidget.paginated != widget.paginated ||
        oldWidget.filePath != widget.filePath) {
      _disposeControllers();
      _createController(_lastPage);
    }
  }

  void _handlePageChanged(int page) {
    _lastPage = page;
    widget.onPageChanged(page);
  }

  /// Public hook used by the jump-to-page dialog and bookmark navigation.
  Future<void> jumpToPage(int page) async {
    const duration = Duration(milliseconds: 250);
    if (_pageController != null) {
      await _pageController!.animateToPage(
        page,
        duration: duration,
        curve: Curves.easeInOut,
      );
    } else {
      await _scrollController!.animateToPage(
        pageNumber: page,
        duration: duration,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.paginated) {
      return PdfView(
        controller: _pageController!,
        scrollDirection: Axis.horizontal,
        pageSnapping: true,
        onDocumentLoaded: (doc) => widget.onTotalPages?.call(doc.pagesCount),
        onPageChanged: _handlePageChanged,
        builders: PdfViewBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, error) =>
              Center(child: Text('Could not open PDF: $error')),
        ),
      );
    }

    return PdfViewPinch(
      controller: _scrollController!,
      onDocumentLoaded: (doc) => widget.onTotalPages?.call(doc.pagesCount),
      onPageChanged: _handlePageChanged,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        pageLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, error) =>
            Center(child: Text('Could not open PDF: $error')),
      ),
    );
  }
}
