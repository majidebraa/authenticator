import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'secure_token_storage.dart';
import 'token_model.dart';
import 'package:share_plus/share_plus.dart';


class ImportExportScreen extends StatefulWidget {
  final List<TokenModel> tokens;
  final SecureTokenStorage storage;

  const ImportExportScreen({super.key, required this.tokens, required this.storage});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {

  @override
  void initState() {
    super.initState();
  }

  Future<void> _exportToClipboard() async {
    final jsonStr = jsonEncode(widget.tokens.map((t) => t.toJson()).toList());
    await Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _importFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      final decoded = jsonDecode(data.text!);
      for (var item in decoded) {
        final token = TokenModel.fromJson(item);
        if (!widget.tokens.any((t) =>
        t.secret == token.secret &&
            t.issuer == token.issuer &&
            t.account == token.account)) {
          widget.tokens.add(token);
        }
      }
      await widget.storage.save(widget.tokens);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Import from clipboard completed')));
    }
  }

  Future<void> _exportToFile() async {
    try {
      final jsonStr = jsonEncode(widget.tokens.map((t) => t.toJson()).toList());

      // Get a directory to save file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/otp_backup.json');

      // Write JSON
      await file.writeAsString(jsonStr);

      // Share the file using ShareParams
      final params = ShareParams(
        files: [XFile(file.path)],
        fileNameOverrides: ['otp_backup.json'], // optional: override filename
        text: 'OTP Backup',
      );

      await SharePlus.instance.share(params);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Exported successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select OTP backup',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      try {
        final List<dynamic> list = jsonDecode(content);
        final imported = list.map((e) => TokenModel.fromJson(e)).toList();
        setState(() {
          widget.tokens.addAll(imported.where((t) => !widget.tokens.contains(t)));
        });
        await widget.storage.save(widget.tokens);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Imported from file')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid file')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import / Export OTPs')),
      body: ListView(
        children: [
          Card(
            elevation: 0,
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Export to Clipboard'),
              subtitle: const Text('Copy all OTPs as JSON to clipboard'),
              onTap: _exportToClipboard,
            ),
          ),
          Card(
            elevation: 0,
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.paste),
              title: const Text('Import from Clipboard'),
              subtitle: const Text('Paste OTP JSON from clipboard'),
              onTap: () =>_importFromClipboard(context),
            ),
          ),
          Card(
            elevation: 0,
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Export to File'),
              subtitle: const Text('Save OTP backup as a JSON file'),
              onTap: _exportToFile,
            ),
          ),
          Card(
            elevation: 0,
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Import from File'),
              subtitle: const Text('Load OTPs from a JSON backup file'),
              onTap: _importFromFile,
            ),
          ),
        ],
      ),
    );
  }
}
