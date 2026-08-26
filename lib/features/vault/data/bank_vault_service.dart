import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BankVaultEntry {
  final String id;
  final String bankName;
  final String username;
  final String password;
  final String note;

  const BankVaultEntry({
    required this.id,
    required this.bankName,
    required this.username,
    required this.password,
    required this.note,
  });

  factory BankVaultEntry.fromJson(Map<String, dynamic> json) => BankVaultEntry(
        id: json['id'] as String,
        bankName: json['bankName'] as String? ?? '',
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bankName': bankName,
        'username': username,
        'password': password,
        'note': note,
      };
}

class BankVaultService {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _key = 'bank_vault_entries_v1';

  Future<List<BankVaultEntry>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => BankVaultEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<BankVaultEntry> entries) async {
    await _storage.write(
      key: _key,
      value: jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
