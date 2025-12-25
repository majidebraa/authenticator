import 'package:authenticator/token_model.dart';
import 'package:flutter/material.dart';

class EditOtpDialog extends StatefulWidget {
  final TokenModel token;
  const EditOtpDialog({super.key, required this.token});

  @override
  State<EditOtpDialog> createState() => _EditOtpDialogState();
}

class _EditOtpDialogState extends State<EditOtpDialog> {
  late TextEditingController issuer;
  late TextEditingController account;

  @override
  void initState() {
    super.initState();
    issuer = TextEditingController(text: widget.token.issuer);
    account = TextEditingController(text: widget.token.account);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit OTP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: issuer, decoration: const InputDecoration(labelText: 'Issuer')),
          TextField(controller: account, decoration: const InputDecoration(labelText: 'Account')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              TokenModel(
                issuer: issuer.text,
                account: account.text,
                secret: widget.token.secret,
                digits: widget.token.digits,
                period: widget.token.period,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
