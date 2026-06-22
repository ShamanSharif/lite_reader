/// The two book formats the reader engine understands.
///
/// Kept deliberately small and serialization-friendly so it can be persisted
/// in Hive / HydratedBloc as a plain string.
enum BookFormat {
  pdf,
  epub;

  /// Resolves a [BookFormat] from a file path / extension.
  ///
  /// Returns `null` when the extension is not supported, letting callers
  /// decide how to reject the file rather than throwing here.
  static BookFormat? fromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return BookFormat.pdf;
    if (lower.endsWith('.epub')) return BookFormat.epub;
    return null;
  }

  /// Lower-case extension without the leading dot (`pdf` / `epub`).
  String get extension => name;

  bool get isPdf => this == BookFormat.pdf;
  bool get isEpub => this == BookFormat.epub;
}
