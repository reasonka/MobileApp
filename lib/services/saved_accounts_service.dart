import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedAccount {
  final String uid;
  final String email;
  final String name;
  final int avatarIndex;

  const SavedAccount({
    required this.uid,
    required this.email,
    required this.name,
    required this.avatarIndex,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'avatarIndex': avatarIndex,
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
        uid: json['uid'] as String? ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        avatarIndex: json['avatarIndex'] as int? ?? 0,
      );
}

/// Stores recently used accounts on-device for quick switching.
class SavedAccountsService {
  SavedAccountsService._();
  static final instance = SavedAccountsService._();

  static const _accountsKey = 'saved_accounts';
  static const _pendingEmailKey = 'pending_switch_email';
  static const _maxAccounts = 5;

  Future<List<SavedAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavedAccount.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAccount(SavedAccount account) async {
    if (account.uid.isEmpty || account.email.isEmpty) return;

    final existing = await loadAccounts();
    final updated = [
      account,
      ...existing.where((a) => a.uid != account.uid),
    ].take(_maxAccounts).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _accountsKey,
      jsonEncode(updated.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> removeAccount(String uid) async {
    final updated = (await loadAccounts()).where((a) => a.uid != uid).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _accountsKey,
      jsonEncode(updated.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> setPendingSwitchEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingEmailKey, email);
  }

  Future<String?> consumePendingSwitchEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_pendingEmailKey);
    if (email != null) await prefs.remove(_pendingEmailKey);
    return email;
  }
}
