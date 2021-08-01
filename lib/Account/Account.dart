import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart';

import '../path.dart';

var Account = account();

class account {
  static late io.Directory _ConfigFolder = configHome;
  static late io.File _AccountFile =
      io.File(join(_ConfigFolder.absolute.path, "accounts.json"));
  static late Map _account = json.decode(_AccountFile.readAsStringSync());

  static void Add(Type, Token, UUID, UserName, Account, Password) {
    _account[Type][UUID] = {
      "AccessToken": Token,
      "UUID": UUID,
      "UserName": UserName,
      "Account": Account,
      "Password": Password
    };
    Save();
  }

  static Map GetByIndex(String Type, int Index) {
    return _account[Type][_account[Type].keys.toList()[Index]];
  }

  static Map GetByUUID(String Type, String UUID) {
    return _account[Type][UUID];
  }

  static Map GetAll() {
    return _account;
  }

  static void SetIndex(Index) {
    _account["index"] = Index;
    Save();
  }

  static void SetType(Type) {
    _account["type"] = Type;
    Save();
  }

  static int GetIndex() {
    if (_account["index"] == null) {
      _account["index"] = -1;
    }
    return _account["index"];
  }

  static String GetType() {
    return _account["type"];
  }

  static void Save() {
    _AccountFile.writeAsStringSync(json.encode(_account));
  }
}
