import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';

import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Model/IO/JsonStorage.dart';
import 'package:rpmlauncher/Widget/RPMNetworkImage.dart';

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
    try {
      return RPMNetworkImage(src: "https://crafatar.com/avatars/$uuid?overlay");
    } catch (e) {
      return Icon(Icons.person);
    }
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
  File get _file => GameRepository.getAccountFile();
  late JsonStorage _storage;

  AccountStorage() {
    _storage = JsonStorage(_file);
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
    Map? _accounts = _storage.getItem('account');
    _accounts?.remove(_accounts.keys.toList()[index]);
    _storage.setItem("account", _accounts);
  }

  void removeByUUID(String uuid) {
    Map? _accounts = _storage.getItem('account');
    _accounts?.remove(uuid);
    _storage.setItem("account", _accounts);
  }

  Map getAll() {
    return _storage.toMap();
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
    Map? _accounts = _storage.getItem('account');

    _accounts ??= {};

    _accounts[account.uuid] = account.toJson();

    _storage.setItem("account", _accounts);

    if (getIndex() == null) {
      setIndex(0);
    }
  }

  Account getByIndex(int index) {
    Map _accounts = _storage.getItem('account');
    return Account.fromJson(_accounts[_accounts.keys.toList()[index]]);
  }

  Account getByUUID(String uuid) {
    return Account.fromJson(_storage.getItem('account')[uuid]);
  }
}
