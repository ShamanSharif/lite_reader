import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/enums/reader_enums.dart';
import 'core/theme/reader_palette.dart';
import 'data/services/file_ingestion_service.dart';
import 'data/services/library_scan_service.dart';
import 'domain/entities/reader_settings.dart';
import 'domain/repositories/book_reader_repository.dart';
import 'presentation/blocs/library/library_cubit.dart';
import 'presentation/blocs/library_settings/library_settings_cubit.dart';
import 'presentation/blocs/reader_settings/reader_settings_cubit.dart';
import 'presentation/screens/library_screen.dart';
import 'presentation/screens/reader_screen.dart';

/// Wires dependencies into the widget tree and bridges the Android "Open with…"
/// intent: a [MethodChannel] receives a cached file path from the native side,
/// which we import and open immediately.
class LiteReaderApp extends StatefulWidget {
  const LiteReaderApp({
    super.key,
    required this.repository,
    required this.ingestionService,
    required this.scanService,
  });

  final BookReaderRepository repository;
  final FileIngestionService ingestionService;
  final LibraryScanService scanService;

  @override
  State<LiteReaderApp> createState() => _LiteReaderAppState();
}

class _LiteReaderAppState extends State<LiteReaderApp> {
  static const _channel = MethodChannel('com.example.lite_reader/intents');

  final _navigatorKey = GlobalKey<NavigatorState>();
  late final LibraryCubit _libraryCubit;

  @override
  void initState() {
    super.initState();
    _libraryCubit = LibraryCubit(
      repository: widget.repository,
      ingestionService: widget.ingestionService,
      scanService: widget.scanService,
    )..load();

    // Handle files opened from other apps while we are already running, and
    // pull any file that launched us cold.
    _channel.setMethodCallHandler(_onPlatformCall);
    _channel.invokeMethod<String>('getInitialFile').then((path) {
      if (path != null) _handleIncomingFile(path);
    });
  }

  Future<void> _onPlatformCall(MethodCall call) async {
    if (call.method == 'openFile' && call.arguments is String) {
      await _handleIncomingFile(call.arguments as String);
    }
  }

  Future<void> _handleIncomingFile(String path) async {
    final result = await widget.ingestionService.importFromPath(path);
    if (result is IngestionSuccess) {
      await widget.repository.addBook(result.book);
      _navigatorKey.currentState?.push(ReaderScreen.route(result.book));
    }
  }

  @override
  void dispose() {
    _libraryCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<BookReaderRepository>.value(
          value: widget.repository,
        ),
        RepositoryProvider<FileIngestionService>.value(
          value: widget.ingestionService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ReaderSettingsCubit()),
          BlocProvider(create: (_) => LibrarySettingsCubit()),
          BlocProvider.value(value: _libraryCubit),
        ],
        child: BlocBuilder<ReaderSettingsCubit, ReaderSettings>(
          buildWhen: (a, b) => a.themeMode != b.themeMode,
          builder: (context, settings) {
            final isDark = settings.themeMode == ReaderThemeMode.dark;
            return MaterialApp(
              navigatorKey: _navigatorKey,
              title: 'Lite Reader',
              debugShowCheckedModeBanner: false,
              theme: ReaderPalette.of(ReaderThemeMode.light).toThemeData(),
              darkTheme: ReaderPalette.of(ReaderThemeMode.dark).toThemeData(),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const LibraryScreen(),
            );
          },
        ),
      ),
    );
  }
}
