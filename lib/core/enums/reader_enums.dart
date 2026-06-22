/// Orientation lock options surfaced in the reader settings.
enum ReaderOrientation { auto, portrait, landscape }

/// The visual reading themes. Sepia is treated as a first-class mode rather
/// than a tweak of light/dark because its palette differs meaningfully.
enum ReaderThemeMode { light, dark, sepia }

/// How the reader advances through content.
///  * [continuousScroll] — vertical scroll (default, best for PDFs/long EPUBs).
///  * [paginated] — discrete page-by-page swiping, like a physical book.
enum ReadingMode { continuousScroll, paginated }
