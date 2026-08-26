import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BankVaultEntry {
  final String id;
  final String bankName;
  final String username;
  final String password;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BankVaultEntry({
    required this.id,
    required this.bankName,
    required this.username,
    required this.password,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  BankVaultEntry copyWith({
    String? bankName,
    String? username,
    String? password,
    String? note,
    DateTime? updatedAt,
  }) =>
      BankVaultEntry(
        id: id,
        bankName: bankName ?? this.bankName,
        username: username ?? this.username,
        password: password ?? this.password,
        note: note ?? this.note,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory BankVaultEntry.fromJson(Map<String, dynamic> json) {
    final fallback = DateTime.now();
    return BankVaultEntry(
      id: json['id'] as String,
      bankName: json['bankName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? fallback,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? fallback,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bankName': bankName,
        'username': username,
        'password': password,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
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
