import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:authenticator/token_model.dart';

class SecureTokenStorage {
  static const _key = 'tokens';
  final _storage = const FlutterSecureStorage();


  Future<List<TokenModel>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => TokenModel.fromJson(e)).toList();
  }


  Future<void> save(List<TokenModel> tokens) async {
    await _storage.write(
      key: _key,
      value: jsonEncode(tokens.map((e) => e.toJson()).toList()),
    );
  }
}