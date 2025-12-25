import 'dart:async';

import 'package:authenticator/totp_timer_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'edit_otp_dialog.dart';
import 'import_export_screen.dart';
import 'manual_otp_dialog.dart';
import 'qr_scanner_screen.dart';
import 'secure_token_storage.dart';
import 'token_model.dart';
import 'totp.dart';

class TokenListScreen extends StatefulWidget {
  const TokenListScreen({super.key});

  @override
  State<TokenListScreen> createState() => _TokenListScreenState();
}

class _TokenListScreenState extends State<TokenListScreen> {
  final _storage = SecureTokenStorage();
  final List<TokenModel> _tokens = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _storage.load();
    setState(() => _tokens.addAll(items));
  }

  bool _exists(TokenModel token) {
    return _tokens.any(
      (t) =>
          t.secret == token.secret &&
          t.issuer == token.issuer &&
          t.account == token.account,
    );
  }

  Future<void> _addToken(TokenModel token) async {
    if (_exists(token)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP already exists')));
      return;
    }
    setState(() => _tokens.add(token));
    await _storage.save(_tokens);
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete OTP'),
        content: const Text('Are you sure you want to delete this token?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openImportExportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImportExportScreen(tokens: _tokens, storage: _storage),
      ),
    ).then((_) => setState(() {}));
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTP copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: _openImportExportScreen,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _tokens.length,
        itemBuilder: (context, index) {
          final token = _tokens[index];

          final code = TOTP.generate(
            secret: token.secret,
            digits: token.digits,
            period: token.period,
          );

          return Dismissible(
            key: ValueKey('${token.secret}-${token.account}'),
            direction: DismissDirection.horizontal,

            /// CONFIRM BASED ON DIRECTION
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // EDIT
                final updated = await showDialog<TokenModel>(
                  context: context,
                  builder: (_) => EditOtpDialog(token: token),
                );
                if (updated != null) {
                  setState(() {
                    final i = _tokens.indexOf(token);
                    if (i != -1) _tokens[i] = updated;
                  });
                  await _storage.save(_tokens);
                }
                return false; // do NOT dismiss
              }

              // DELETE
              return await _confirmDelete();
            },

            onDismissed: (_) async {
              setState(() {
                _tokens.removeWhere(
                  (t) =>
                      t.secret == token.secret &&
                      t.account == token.account &&
                      t.issuer == token.issuer,
                );
              });
              await _storage.save(_tokens);
            },

            /// LEFT → RIGHT (EDIT)
            background: Container(
              color: Colors.blue,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.edit, color: Colors.white),
            ),

            /// RIGHT → LEFT (DELETE)
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),

            child: Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text('${token.issuer} (${token.account})'),
                subtitle: GestureDetector(
                  onTap: () => _copyCode(code),
                  onLongPress: () => _copyCode(code),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                trailing: TotpTimerIndicator(period: token.period),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan QR code'),
                onTap: () async {
                  Navigator.pop(context);
                  final token = await Navigator.push<TokenModel>(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                  );
                  if (token != null) _addToken(token);
                },
              ),
              ListTile(
                leading: const Icon(Icons.keyboard),
                title: const Text('Enter setup key'),
                onTap: () async {
                  Navigator.pop(context);
                  final token = await showDialog<TokenModel>(
                    context: context,
                    builder: (_) => const ManualOtpDialog(),
                  );
                  if (token != null) _addToken(token);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
