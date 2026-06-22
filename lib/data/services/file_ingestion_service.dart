import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/enums/book_format.dart';
import '../../domain/entities/book.dart';

/// Outcome of an ingestion attempt. Using a sealed result keeps the caller
/// (the library cubit) free of try/catch noise and makes every branch explicit.
sealed class IngestionResult {
  const IngestionResult();
}

class IngestionSuccess extends IngestionResult {
  const IngestionSuccess(this.book);
  final Book book;
}

/// User dismissed the picker — not an error, just nothing to do.
class IngestionCancelled extends IngestionResult {
  const IngestionCancelled();
}

class IngestionFailure extends IngestionResult {
  const IngestionFailure(this.message);
  final String message;
}

/// Owns the "get a file from the device into our private storage" flow.
///
/// Why this is a separate service and NOT part of [BookReaderRepository]:
///  * It is pure platform/IO (picker + filesystem), not persistence.
///  * It must copy bytes into app-private storage so we never depend on the
///    original URI staying valid — critical on Android, where SAF content URIs
///    are revoked and where API 21 has no broad storage permission model.
///
/// API-21 safety: `file_picker` returns a real cached file path on Android, and
/// we copy with `dart:io` only. No scoped-storage / MediaStore APIs (API 29+)
/// and no runtime permission that requires API 23+ are used here.
class FileIngestionService {
  FileIngestionService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Opens the system picker, then delegates to [importFromPath].
  Future<IngestionResult> pickAndImport() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.allowedExtensions,
        withData: false, // we copy from path; avoids loading huge files in RAM
      );
    } catch (e) {
      return IngestionFailure('Could not open file picker: $e');
    }

    final path = result?.files.single.path;
    if (path == null) return const IngestionCancelled();

    return importFromPath(path);
  }

  /// Copies the file at [sourcePath] into the app's private books directory and
  /// returns a [Book] describing the imported copy. Safe to call directly for
  /// "open with…" intents in addition to the in-app picker.
  Future<IngestionResult> importFromPath(String sourcePath) async {
    final format = BookFormat.fromPath(sourcePath);
    if (format == null) {
      return const IngestionFailure('Unsupported file type. Use PDF or EPUB.');
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      return const IngestionFailure('The selected file no longer exists.');
    }

    try {
      final booksDir = await _ensureBooksDir();
      final id = _uuid.v4();
      final destName = '$id.${format.extension}';
      final destPath = p.join(booksDir.path, destName);

      // Stream copy keeps memory flat even for large PDFs on old devices.
      await source.copy(destPath);

      final stat = await File(destPath).stat();
      final book = Book(
        id: id,
        title: _deriveTitle(sourcePath),
        filePath: destPath,
        sourcePath: sourcePath,
        format: format,
        fileSizeBytes: stat.size,
        dateAdded: DateTime.now(),
      );
      return IngestionSuccess(book);
    } on FileSystemException catch (e) {
      return IngestionFailure('Failed to import file: ${e.message}');
    } catch (e) {
      return IngestionFailure('Unexpected import error: $e');
    }
  }

  /// Deletes the on-disk copy (and cover, if present) for a removed book.
  Future<void> deleteFiles(Book book) async {
    await _safeDelete(book.filePath);
    if (book.coverPath != null) await _safeDelete(book.coverPath!);
  }

  Future<Directory> _ensureBooksDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, AppConstants.booksDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Best-effort cleanup; a leftover file should never block a delete.
    }
  }

  String _deriveTitle(String sourcePath) {
    final base = p.basenameWithoutExtension(sourcePath).trim();
    return base.isEmpty ? 'Untitled' : base.replaceAll('_', ' ');
  }
}
