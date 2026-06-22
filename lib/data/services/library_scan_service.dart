import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../../core/enums/book_format.dart';
import '../../domain/repositories/book_reader_repository.dart';
import 'file_ingestion_service.dart';

/// Summary of a completed scan, surfaced to the UI.
class ScanReport {
  const ScanReport({
    this.imported = 0,
    this.skipped = 0,
    this.failed = 0,
    this.permissionDenied = false,
  });

  final int imported;
  final int skipped;
  final int failed;
  final bool permissionDenied;

  bool get foundNothingNew => imported == 0 && !permissionDenied;
}

/// Recursively crawls user-configured folders for `.pdf` / `.epub` files and
/// imports any that aren't already in the library.
///
/// API-21 note: on API 21–22 `READ_EXTERNAL_STORAGE` is install-time granted,
/// so the permission request resolves immediately. On 23–28 it prompts once.
/// We crawl with `dart:io` only — no MediaStore / scoped-storage APIs — and
/// dedup against each book's recorded `sourcePath`.
class LibraryScanService {
  LibraryScanService({
    required BookReaderRepository repository,
    required FileIngestionService ingestionService,
  }) : _repository = repository,
       _ingestion = ingestionService;

  final BookReaderRepository _repository;
  final FileIngestionService _ingestion;

  Future<bool> ensurePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted || status.isLimited;
  }

  /// Scans every folder in [folders]. Pass [requestPermission] = false when the
  /// caller has already secured access (e.g. just-picked SAF directory).
  Future<ScanReport> scan(
    List<String> folders, {
    bool requestPermission = true,
  }) async {
    if (folders.isEmpty) return const ScanReport();

    if (requestPermission && !await ensurePermission()) {
      return const ScanReport(permissionDenied: true);
    }

    final known = await _repository.getKnownSourcePaths();
    var imported = 0, skipped = 0, failed = 0;

    for (final folderPath in folders) {
      final dir = Directory(folderPath);
      if (!await dir.exists()) continue;

      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        if (BookFormat.fromPath(entity.path) == null) continue;
        if (known.contains(entity.path)) {
          skipped++;
          continue;
        }

        final result = await _ingestion.importFromPath(entity.path);
        switch (result) {
          case IngestionSuccess(:final book):
            await _repository.addBook(book);
            known.add(entity.path);
            imported++;
          case IngestionFailure():
            failed++;
          case IngestionCancelled():
            break;
        }
      }
    }

    return ScanReport(imported: imported, skipped: skipped, failed: failed);
  }
}
