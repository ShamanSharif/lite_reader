import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/book.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/book_reader_repository.dart';

/// Grid tile for the (tablet-friendly) shelf. Shows a generated cover, the
/// format badge, title/author and a live progress bar.
class BookGridCard extends StatelessWidget {
  const BookGridCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<BookReaderRepository>();
    final scheme = Theme.of(context).colorScheme;
    final isPdf = book.format.isPdf;
    final accent = isPdf ? Colors.red.shade600 : Colors.indigo.shade500;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: accent.withValues(alpha: 0.10),
                alignment: Alignment.center,
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.menu_book,
                  size: 40,
                  color: accent,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (book.author != null)
                    Text(
                      book.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 6),
                  FutureBuilder<ReadingProgress?>(
                    future: repository.getProgress(book.id),
                    builder: (context, snapshot) {
                      final pct = snapshot.data?.percentage ?? 0;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct == 0 ? null : pct,
                          minHeight: 4,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
