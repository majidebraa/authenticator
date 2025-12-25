import 'dart:math';
import 'dart:typed_data';
import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';

class TOTP {
  static String generate({
    required String secret,
    int digits = 6,
    int period = 30,
  }) {
    final key = base32.decode(secret.replaceAll(' ', '').toUpperCase());
    final time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final counter = time ~/ period;


    final data = ByteData(8)..setInt64(0, counter);
    final hmac = Hmac(sha1, key).convert(data.buffer.asUint8List());


    final offset = hmac.bytes.last & 0xf;
    final binary = ((hmac.bytes[offset] & 0x7f) << 24) |
    ((hmac.bytes[offset + 1] & 0xff) << 16) |
    ((hmac.bytes[offset + 2] & 0xff) << 8) |
    (hmac.bytes[offset + 3] & 0xff);


    final otp = binary % pow(10, digits).toInt();
    return otp.toString().padLeft(digits, '0');
  }
}