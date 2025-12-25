import 'package:flutter/material.dart';
import 'token_model.dart';

class ManualOtpDialog extends StatefulWidget {
  const ManualOtpDialog({super.key});

  @override
  State<ManualOtpDialog> createState() => _ManualOtpDialogState();
}

class _ManualOtpDialogState extends State<ManualOtpDialog> {
  final _issuer = TextEditingController();
  final _account = TextEditingController();
  final _secret = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter setup key'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _issuer,
              decoration: const InputDecoration(labelText: 'Issuer'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _account,
              decoration: const InputDecoration(labelText: 'Account'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _secret,
              decoration: const InputDecoration(
                labelText: 'Setup key (Base32)',
                hintText: 'JBSWY3DPEHPK3PXP',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!RegExp(r'^[A-Z2-7 ]+$').hasMatch(v.toUpperCase())) {
                  return 'Invalid Base32 key';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          child: const Text('Add'),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            Navigator.pop(
              context,
              TokenModel(
                issuer: _issuer.text.trim(),
                account: _account.text.trim(),
                secret: _secret.text.replaceAll(' ', '').toUpperCase(),
              ),
            );
          },
        ),
      ],
    );
  }
}
