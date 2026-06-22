import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/datasources/local_book_datasource.dart';
import 'data/repositories/book_reader_repository_impl.dart';
import 'data/services/file_ingestion_service.dart';
import 'data/services/library_scan_service.dart';

/// Composition root. All async setup happens here, once, before `runApp`:
///  1. Hive (pure-Dart local DB) for the library/progress/bookmarks.
///  2. HydratedBloc storage (backed by the app documents dir) for settings.
///  3. The data source -> repository -> services chain is assembled and
///     injected into [LiteReaderApp].
///
/// Nothing here touches APIs newer than Android 21.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Local key/value store.
  await Hive.initFlutter();
  final dataSource = await LocalBookDataSource.open();

  // 2. Persisted bloc state (reader settings).
  final docsDir = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: Directory(docsDir.path),
  );

  // 3. Assemble the dependency graph (manual DI keeps it transparent).
  final ingestionService = FileIngestionService();
  final repository = BookReaderRepositoryImpl(
    dataSource: dataSource,
    ingestionService: ingestionService,
  );
  final scanService = LibraryScanService(
    repository: repository,
    ingestionService: ingestionService,
  );

  runApp(
    LiteReaderApp(
      repository: repository,
      ingestionService: ingestionService,
      scanService: scanService,
    ),
  );
}
