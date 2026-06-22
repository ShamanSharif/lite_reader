import 'dart:io';

import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';

import '../../core/theme/reader_palette.dart';

/// A format-neutral table-of-contents entry. We map `epub_view`'s internal
/// chapter type onto this so the rest of the app never depends on a symbol the
/// package doesn't publicly export.
class EpubChapterRef {
  const EpubChapterRef({required this.title, required this.startIndex});
  final String title;
  final int startIndex;
}

/// EPUB rendering engine wrapper built on `epub_view`, which parses standard
/// EPUB markup (via the pure-Dart `epubx` package) into reflowable Flutter
/// widgets — no WebView, so it is light and works fine on API 21.
///
/// Reader customization (font scale / line spacing / theme color) is applied
/// through `DefaultBuilderOptions.textStyle`. Position is tracked as a CFI so
/// reading can resume at the exact paragraph.
class EpubReaderView extends StatefulWidget {
  const EpubReaderView({
    super.key,
    required this.filePath,
    required this.initialCfi,
    required this.palette,
    required this.fontScale,
    required this.lineHeight,
    required this.onLocationChanged,
  });

  final String filePath;

  /// Canonical fragment identifier to resume at (null => start of book).
  final String? initialCfi;

  final ReaderPalette palette;
  final double fontScale;
  final double lineHeight;

  /// Reports the current CFI + progress fraction as the user reads.
  final void Function(String? cfi, double percentage) onLocationChanged;

  @override
  State<EpubReaderView> createState() => EpubReaderViewState();
}

class EpubReaderViewState extends State<EpubReaderView> {
  late final EpubController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EpubController(
      document: EpubDocument.openFile(File(widget.filePath)),
      epubCfi: widget.initialCfi,
    );
  }

  /// Surfaces the table of contents so the parent can show a chapter drawer.
  EpubController get controller => _controller;

  /// Chapter list for the TOC drawer (empty until the document loads).
  List<EpubChapterRef> tableOfContents() => _controller
      .tableOfContents()
      .map(
        (c) => EpubChapterRef(
          title: c.title?.trim().isNotEmpty == true
              ? c.title!.trim()
              : 'Chapter',
          startIndex: c.startIndex,
        ),
      )
      .toList();

  /// Jumps to a saved CFI bookmark.
  void gotoCfi(String cfi) => _controller.gotoEpubCfi(cfi);

  /// Jumps to a TOC entry's paragraph index.
  void scrollToIndex(int index) => _controller.scrollTo(index: index);

  /// Current CFI for bookmarking / note anchoring.
  String? currentCfi() => _controller.generateEpubCfi();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const double _baseFontSize = 16;

  @override
  Widget build(BuildContext context) {
    return EpubView(
      controller: _controller,
      onChapterChanged: (value) {
        // Persist the live CFI + a coarse progress fraction on every move.
        widget.onLocationChanged(
          _controller.generateEpubCfi(),
          value?.progress ?? 0,
        );
      },
      builders: EpubViewBuilders<DefaultBuilderOptions>(
        options: DefaultBuilderOptions(
          textStyle: TextStyle(
            fontSize: _baseFontSize * widget.fontScale,
            height: widget.lineHeight,
            color: widget.palette.text,
          ),
        ),
        loaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, error) =>
            Center(child: Text('Could not open EPUB: $error')),
      ),
    );
  }
}
