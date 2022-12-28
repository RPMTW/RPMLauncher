import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/config/json_storage.dart';
import 'package:rpmlauncher/launcher/game_repository.dart';
import 'package:rpmlauncher/ui/widget/rpml_network_image.dart';

/// Now only support Microsoft Account
enum AccountType {
  mojang,
  microsoft,
}

class Account {
  final AccountType type;
  final String accessToken;
  final String uuid;
  final String username;

  final String? email;
  final Credentials? credentials;

  Widget get imageWidget {
    return RPMLNetworkImage(
        src: 'https://minotar.net/helm/$uuid',
        errorWidget: const Icon(Icons.person));
  }

  Account(this.type, this.accessToken, this.uuid, this.username,
      {this.email, this.credentials});

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'accessToken': accessToken,
      'uuid': uuid,
      'username': username,
      'email': email,
      'credentials': credentials?.toJson(),
    };
  }

  @override
  String toString() {
    return json.encode(toJson());
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(AccountType.values.byName(json['type']), json['accessToken'],
        json['uuid'], json['username'],
        email: json['email'],
        credentials: json['credentials'] != null
            ? Credentials.fromJson(json['credentials'])
            : null);
  }

  Future<void> save() async => await AccountStorage.save(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Account &&
        other.type == type &&
        other.accessToken == accessToken &&
        other.uuid == uuid &&
        other.username == username &&
        other.email == email &&
        other.credentials == credentials;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        accessToken.hashCode ^
        uuid.hashCode ^
        username.hashCode ^
        email.hashCode ^
        credentials.hashCode;
  }
}

class AccountStorage {
  static final JsonStorage _storage =
      JsonStorage(GameRepository.getAccountFile());

  static bool get hasAccount => getCount() > 0 && getDefault() != null;

  static Future<void> init() {
    return _storage.init();
  }

  static Future<void> add(
      AccountType type, String accessToken, String uuid, String userName,
      {String? email, Credentials? credentials}) async {
    final account = Account(type, accessToken, uuid, userName,
        email: email, credentials: credentials);
    await account.save();
  }

  static Account? getDefault() {
    int? index = getIndex();
    try {
      return index != null ? getByIndex(index) : null;
    } catch (e) {
      return null;
    }
  }

  static void removeByIndex(int index) {
    Map? accounts = _storage.getItem('account');
    accounts?.remove(accounts.keys.toList()[index]);
    _storage.setItem('account', accounts);
  }

  static void removeByUUID(String uuid) {
    Map? accounts = _storage.getItem('account');
    accounts?.remove(uuid);
    _storage.setItem('account', accounts);
  }

  static Future<Map<String, Object?>> getAll() {
    return _storage.getAll();
  }

  static int getCount() {
    return _storage.getItem('account') == null
        ? 0
        : _storage.getItem('account').keys.length;
  }

  static Future<void> setIndex(int index) async {
    await _storage.setItem('index', index);
  }

  static int? getIndex() {
    return _storage.getItem('index');
  }

  static Future<void> save(Account account) async {
    Map? accounts = _storage.getItem('account');

    accounts ??= {};

    accounts[account.uuid] = account.toJson();

    await _storage.setItem('account', accounts);

    if (getIndex() == null) {
      await setIndex(0);
    }
  }

  static Account getByIndex(int index) {
    Map accounts = _storage.getItem('account');
    return Account.fromJson(accounts[accounts.keys.toList()[index]]);
  }

  static Account getByUUID(String uuid) {
    return Account.fromJson(_storage.getItem('account')[uuid]);
  }
}
