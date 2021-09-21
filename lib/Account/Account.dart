import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';

import '../main.dart';
import '../path.dart';

var Account = account();

class account {
  static io.File _AccountFile = GameRepository.getAccountFile();
  static Map _account = json.decode(_AccountFile.readAsStringSync());

  static String Mojang = 'mojang';
  static String Microsoft = 'microsoft';

  static void Add(Type, Token, UUID, UserName, Account, [Credentials]) {
    if (_account['Account'] == null) {
      _account['Account'] = {};
    }

    _account['Account'][UUID] = {
      "AccessToken": Token,
      "UUID": UUID,
      "UserName": UserName,
      "Account": Account,
      "Type": Type,
    };
    if (Credentials != null) {
      _account['Account'][UUID]['Credentials'] = Credentials;
    }
    Save();
  }

  static Map getByIndex(int Index) {
    return _account['Account'][_account['Account'].keys.toList()[Index]];
  }

  static Map getByUUID(String UUID) {
    return _account['Account'][UUID];
  }

  static void RemoveByIndex(int Index) {
    _account['Account']
        .remove(_account['Account'].keys.toList()[Index].toString());
    Save();
  }

  static void RemoveUUID(String UUID) {
    _account['Account'].remove(UUID);
    Save();
  }

  static Map getAll() {
    return _account;
  }

  static int getCount() {
    if (_account['Account'] == null) {
      _account['Account'] = {};
    }
    Save();
    return _account['Account'].keys.length;
  }

  static void SetIndex(Index) {
    if (_account["index"] == null) {
      _account["index"] = 1;
    }

    _account["index"] = Index;
    Save();
  }

  static int getIndex() {
    if (_account["index"] == null) {
      _account["index"] = -1;
    }
    return _account["index"];
  }

  static void Save() {
    _AccountFile.writeAsStringSync(json.encode(_account));
  }

  static void Update() {
    _account = json.decode(_AccountFile.readAsStringSync());
  }
}
