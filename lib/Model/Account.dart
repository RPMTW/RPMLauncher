import 'dart:convert';
import 'dart:io';

import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Model/JsonDataClass.dart';

enum AccountType {
  mojang,
  microsoft,
}

class Account extends JsonDataMap {
  final AccountType type;
  final String accessToken;
  final String uuid;
  final String username;

  final String? email;
  final Credentials? credentials;

  static File _file = GameRepository.getAccountFile();
  static Map _data = JsonDataMap.toStaticMap(_file);

  Account(this.type, this.accessToken, this.uuid, this.username, this.email,
      this.credentials)
      : super(GameRepository.getAccountFile());

  static void add(
      AccountType type, String accessToken, String uuid, String userName,
      {String? email, Credentials? credentials}) {
    final account =
        Account(type, accessToken, uuid, userName, email, credentials);
    account.save();
  }

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

  void save() {
    if (rawData['account'] == null) {
      rawData['account'] = {};
    }
    rawData['account'][uuid] = toJson();


    saveData();
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
        AccountType.values.byName(json['type']),
        json['accessToken'],
        json['uuid'],
        json['username'],
        json['email'],
        json['credentials'] != null
            ? Credentials.fromJson(json['credentials'])
            : null);
  }

  factory Account.getByIndex(int index) {
    return Account.fromJson(
        _data['account'][_data['account'].keys.toList()[index]]);
  }

  factory Account.getByUUID(String uuid) {
    return Account.fromJson(_data['account'][uuid]);
  }

  factory Account.getDefault() {
    return Account.getByIndex(Account.getIndex());
  }

  static _saveData() {
    _file.writeAsStringSync(json.encode(_data));
  }

  static void removeByIndex(int index) {
    _data['account'].remove(_data['account'].keys.toList()[index].toString());
    _saveData();
  }

  static void removeUUID(String uuid) {
    _data['account'].remove(uuid);
    _saveData();
  }

  static Map getAll() {
    return _data;
  }

  static int getCount() {
    return _data['account'] == null ? 0 : _data['account'].keys.length;
  }

  static void setIndex(int index) {
    _data["index"] = index;
    _saveData();
  }

  static int getIndex() {
    return _data["index"] ?? -1;
  }
}
