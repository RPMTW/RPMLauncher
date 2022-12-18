import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/config/json_storage.dart';

import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/widget/RPMNetworkImage.dart';

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
    return RPMNetworkImage(
        src: "https://minotar.net/helm/$uuid",
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

  void save() => AccountStorage().save(this);

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
  late JsonStorage _storage;

  AccountStorage() {
    _storage = JsonStorage(GameRepository.getAccountFile());
  }

  bool get hasAccount => getCount() > 0 && getDefault() != null;

  void add(AccountType type, String accessToken, String uuid, String userName,
      {String? email, Credentials? credentials}) {
    final account = Account(type, accessToken, uuid, userName,
        email: email, credentials: credentials);
    account.save();
  }

  Account? getDefault() {
    int? index = getIndex();
    try {
      return index != null ? getByIndex(index) : null;
    } catch (e) {
      return null;
    }
  }

  void removeByIndex(int index) {
    Map? accounts = _storage.getItem('account');
    accounts?.remove(accounts.keys.toList()[index]);
    _storage.setItem("account", accounts);
  }

  void removeByUUID(String uuid) {
    Map? accounts = _storage.getItem('account');
    accounts?.remove(uuid);
    _storage.setItem("account", accounts);
  }

  Future<Map<String, Object?>> getAll() {
    return _storage.getAll();
  }

  int getCount() {
    return _storage.getItem('account') == null
        ? 0
        : _storage.getItem('account').keys.length;
  }

  void setIndex(int index) {
    _storage.setItem("index", index);
  }

  int? getIndex() {
    return _storage.getItem("index");
  }

  void save(Account account) {
    Map? accounts = _storage.getItem('account');

    accounts ??= {};

    accounts[account.uuid] = account.toJson();

    _storage.setItem("account", accounts);

    if (getIndex() == null) {
      setIndex(0);
    }
  }

  Account getByIndex(int index) {
    Map accounts = _storage.getItem('account');
    return Account.fromJson(accounts[accounts.keys.toList()[index]]);
  }

  Account getByUUID(String uuid) {
    return Account.fromJson(_storage.getItem('account')[uuid]);
  }
}
