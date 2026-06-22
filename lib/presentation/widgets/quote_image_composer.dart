import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/enums/reader_enums.dart';
import '../../core/theme/reader_palette.dart';
import '../../domain/entities/book.dart';

/// Full-screen composer that turns a highlighted passage into a shareable
/// quotation image. The visible [_QuoteCard] is wrapped in a [RepaintBoundary];
/// we rasterize that boundary to PNG with `toImage`, write it to a temp file,
/// then hand it to the system share sheet (which covers "save to gallery",
/// messaging apps, etc. without any gallery-specific plugin).
class QuoteImageComposer extends StatefulWidget {
  const QuoteImageComposer({
    super.key,
    required this.book,
    required this.quote,
  });

  final Book book;
  final String quote;

  static Route<void> route({required Book book, required String quote}) =>
      MaterialPageRoute(
        builder: (_) => QuoteImageComposer(book: book, quote: quote),
      );

  @override
  State<QuoteImageComposer> createState() => _QuoteImageComposerState();
}

class _QuoteImageComposerState extends State<QuoteImageComposer> {
  final _boundaryKey = GlobalKey();
  ReaderThemeMode _style = ReaderThemeMode.sepia;
  bool _busy = false;

  Future<Uint8List?> _capture() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<File?> _writeToFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final safeTitle = widget.book.title
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .toLowerCase();
    final file = File(
      p.join(
        dir.path,
        'quote_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.png',
      ),
    );
    return file.writeAsBytes(bytes);
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      final file = await _writeToFile(bytes);
      if (file == null) return;
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'image/png'),
      ], text: '“${widget.quote}” — ${widget.book.title}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ReaderPalette.of(_style);
    return Scaffold(
      appBar: AppBar(title: const Text('Create quote image')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: _QuoteCard(
                    quote: widget.quote,
                    book: widget.book,
                    palette: palette,
                  ),
                ),
              ),
            ),
          ),
          _StyleSelector(
            selected: _style,
            onChanged: (mode) => setState(() => _style = mode),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _busy ? null : _share,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share),
                label: const Text('Save / Share image'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.book,
    required this.palette,
  });

  final String quote;
  final Book book;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u201C',
            style: TextStyle(
              fontSize: 56,
              height: 0.8,
              fontWeight: FontWeight.bold,
              color: palette.accent,
            ),
          ),
          Text(
            quote,
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: palette.accent.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            book.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: palette.text,
            ),
          ),
          if (book.author != null)
            Text(
              book.author!,
              style: TextStyle(
                fontSize: 12,
                color: palette.text.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}

class _StyleSelector extends StatelessWidget {
  const _StyleSelector({required this.selected, required this.onChanged});

  final ReaderThemeMode selected;
  final ValueChanged<ReaderThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<ReaderThemeMode>(
        segments: const [
          ButtonSegment(value: ReaderThemeMode.light, label: Text('Light')),
          ButtonSegment(value: ReaderThemeMode.sepia, label: Text('Sepia')),
          ButtonSegment(value: ReaderThemeMode.dark, label: Text('Dark')),
        ],
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
