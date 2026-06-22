import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/library_scan_service.dart';
import '../../domain/entities/library_settings.dart';
import '../blocs/library/library_cubit.dart';
import '../blocs/library_settings/library_settings_cubit.dart';

/// Manages library-level configuration: the folders the scanner crawls, and a
/// manual "scan now" action.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const SettingsScreen());

  Future<void> _addFolder(BuildContext context) async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null || !context.mounted) return;
    context.read<LibrarySettingsCubit>().addScanFolder(path);
  }

  Future<void> _scanNow(BuildContext context) async {
    final folders = context.read<LibrarySettingsCubit>().state.scanFolders;
    final messenger = ScaffoldMessenger.of(context);
    if (folders.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add a scan folder first.')),
      );
      return;
    }
    final report = await context.read<LibraryCubit>().scanFolders(folders);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(_reportText(report))));
  }

  String _reportText(ScanReport r) {
    if (r.permissionDenied) return 'Storage permission denied.';
    if (r.foundNothingNew) return 'No new books found.';
    return 'Imported ${r.imported} book(s).'
        '${r.failed > 0 ? ' ${r.failed} failed.' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<LibrarySettingsCubit, LibrarySettings>(
        builder: (context, settings) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Scan folders',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'The library scanner looks for PDF and EPUB files inside '
                  'these folders (and their subfolders).',
                ),
              ),
              const SizedBox(height: 8),
              if (settings.scanFolders.isEmpty)
                const ListTile(
                  leading: Icon(Icons.folder_off_outlined),
                  title: Text('No folders added'),
                )
              else
                ...settings.scanFolders.map(
                  (folder) => ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(
                      folder,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => context
                          .read<LibrarySettingsCubit>()
                          .removeScanFolder(folder),
                    ),
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('Add scan folder'),
                onTap: () => _addFolder(context),
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Scan now'),
                subtitle: const Text('Import new books from scan folders'),
                onTap: () => _scanNow(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
