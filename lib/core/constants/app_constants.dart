/// Centralized, magic-number-free configuration values.
class AppConstants {
  AppConstants._();

  /// Sub-directory (inside the app documents dir) where imported books live.
  static const String booksDirName = 'books';

  /// Hive box names.
  static const String booksBoxName = 'library_books';
  static const String progressBoxName = 'reading_progress';
  static const String bookmarksBoxName = 'bookmarks';
  static const String notesBoxName = 'notes';

  /// HydratedBloc storage key for reader settings is derived from the cubit
  /// runtimeType, so nothing is needed here, but we expose bounds for the UI.
  static const double minFontScale = 0.7;
  static const double maxFontScale = 2.2;
  static const double minLineHeight = 1.0;
  static const double maxLineHeight = 2.4;

  static const List<String> allowedExtensions = ['pdf', 'epub'];
}
