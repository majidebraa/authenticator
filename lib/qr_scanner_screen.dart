import 'package:authenticator/token_model.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _handled = false;

  TokenModel _parseOtpAuth(String uri) {
    final parsed = Uri.parse(uri);
    final label = parsed.path.replaceFirst('/', '');
    final parts = label.split(':');

    return TokenModel(
      issuer: parsed.queryParameters['issuer'] ?? parts.first,
      account: parts.length > 1 ? parts[1] : 'account',
      secret: parsed.queryParameters['secret']!,
      digits: int.tryParse(parsed.queryParameters['digits'] ?? '6') ?? 6,
      period: int.tryParse(parsed.queryParameters['period'] ?? '30') ?? 30,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
        ),
        onDetect: (BarcodeCapture capture) {
          if (_handled) return;

          for (final barcode in capture.barcodes) {
            final raw = barcode.rawValue;
            if (raw != null && raw.startsWith('otpauth://')) {
              _handled = true;
              final token = _parseOtpAuth(raw);

              Future.microtask(() {
                if (context.mounted) {
                  Navigator.pop(context, token);
                }
              });
              return;
            }
          }
        },
      ),
    );
  }
}
