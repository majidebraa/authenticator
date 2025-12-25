import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'secure_token_storage.dart';
import 'token_model.dart';

class ImportExportScreen extends StatefulWidget {
  final List<TokenModel> tokens;
  final SecureTokenStorage storage;

  const ImportExportScreen({
    super.key,
    required this.tokens,
    required this.storage,
  });

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  bool _loading = false;

  Future<void> _exportToClipboard() async {
    final jsonStr = jsonEncode(widget.tokens.map((t) => t.toJson()).toList());
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _importFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;

    try {
      final List<dynamic> decoded = jsonDecode(data!.text!);
      final imported = decoded.map((e) => TokenModel.fromJson(e)).toList();

      setState(() {
        widget.tokens.addAll(imported.where((t) => !widget.tokens.contains(t)));
      });
      await widget.storage.save(widget.tokens);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imported from clipboard')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid clipboard content')),
      );
    }
  }

  Future<void> _exportToFile() async {
    setState(() => _loading = true);
    try {
      final jsonStr = jsonEncode(widget.tokens.map((t) => t.toJson()).toList());
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/otp_backup.json');
      await file.writeAsString(jsonStr);

      final params = ShareParams(
        files: [XFile(file.path)],
        fileNameOverrides: ['otp_backup.json'],
        text: 'OTP Backup',
      );
      await SharePlus.instance.share(params);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Exported successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select OTP backup',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _loading = true);
    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(content);
      final imported = decoded.map((e) => TokenModel.fromJson(e)).toList();

      setState(() {
        widget.tokens.addAll(imported.where((t) => !widget.tokens.contains(t)));
      });
      await widget.storage.save(widget.tokens);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imported from file')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid file')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      _Option(
        icon: Icons.copy,
        title: 'Export to Clipboard',
        subtitle: 'Copy all OTPs as JSON to clipboard',
        action: _exportToClipboard,
      ),
      _Option(
        icon: Icons.paste,
        title: 'Import from Clipboard',
        subtitle: 'Paste OTP JSON from clipboard',
        action: _importFromClipboard,
      ),
      _Option(
        icon: Icons.save,
        title: 'Export to File',
        subtitle: 'Save OTP backup as a JSON file',
        action: _exportToFile,
      ),
      _Option(
        icon: Icons.folder_open,
        title: 'Import from File',
        subtitle: 'Load OTPs from a JSON backup file',
        action: _importFromFile,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Import / Export OTPs')),
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: options.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final opt = options[index];
              return ListTile(
                leading: Icon(opt.icon),
                title: Text(opt.title),
                subtitle: Text(opt.subtitle),
                onTap: opt.action,
                trailing: const Icon(Icons.chevron_right),
              );
            },
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _Option {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback action;

  _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });
}
