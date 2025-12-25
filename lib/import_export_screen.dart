import 'dart:convert';
import 'dart:io';

import 'package:authenticator/secure_token_storage.dart';
import 'package:authenticator/token_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ImportExportScreen extends StatelessWidget {
  final List<TokenModel> tokens;
  final SecureTokenStorage storage;

  const ImportExportScreen({super.key, required this.tokens, required this.storage});

  Future<void> _exportToFile(BuildContext context) async {
    final jsonStr = jsonEncode(tokens.map((t) => t.toJson()).toList());
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/otps_export.json');
    await file.writeAsString(jsonStr);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to ${file.path}')));
  }

  Future<void> _importFromFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final List decoded = jsonDecode(jsonStr);
      for (var item in decoded) {
        final token = TokenModel.fromJson(item);
        if (!tokens.any((t) =>
        t.secret == token.secret &&
            t.issuer == token.issuer &&
            t.account == token.account)) {
          tokens.add(token);
        }
      }
      await storage.save(tokens);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Import completed')));
    }
  }

  Future<void> _exportToClipboard(BuildContext context) async {
    final jsonStr = jsonEncode(tokens.map((t) => t.toJson()).toList());
    await Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _importFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      final decoded = jsonDecode(data.text!);
      for (var item in decoded) {
        final token = TokenModel.fromJson(item);
        if (!tokens.any((t) =>
        t.secret == token.secret &&
            t.issuer == token.issuer &&
            t.account == token.account)) {
          tokens.add(token);
        }
      }
      await storage.save(tokens);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Import from clipboard completed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import / Export OTPs')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Export to File'),
              onPressed: () => _exportToFile(context),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Import from File'),
              onPressed: () => _importFromFile(context),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Export to Clipboard'),
              onPressed: () => _exportToClipboard(context),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.paste),
              label: const Text('Import from Clipboard'),
              onPressed: () => _importFromClipboard(context),
            ),
          ],
        ),
      ),
    );
  }
}