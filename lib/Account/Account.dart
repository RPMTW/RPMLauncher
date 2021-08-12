import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart';

import '../path.dart';

var Account = account();

class account {
  static io.Directory _ConfigFolder = configHome;
  static io.File _AccountFile =
      io.File(join(_ConfigFolder.absolute.path, "accounts.json"));
  static Map _account = json.decode(_AccountFile.readAsStringSync());

  static String Mojang = 'mojang';
  static String Microsoft = 'microsoft';

  static void Add(Type, Token, UUID, UserName, Account) {
    if (_account[Type] == null) {
      _account[Type] = {};
    }

    _account[Type][UUID] = {
      "AccessToken": Token,
      "UUID": UUID,
      "UserName": UserName,
      "Account": Account,
      "Type": Type
    };
    Save();
  }

  static Map getByIndex(String Type, int Index) {
    return _account[Type][_account[Type].keys.toList()[Index]];
  }

  static Map getByUUID(String Type, String UUID) {
    return _account[Type][UUID];
  }

  static void RemoveByIndex(String Type, int Index) {
    _account[Type].remove(_account[Type].keys.toList()[Index].toString());
    Save();
  }

  static void RemoveUUID(String Type, String UUID) {
    _account[Type].remove(UUID);
    Save();
  }

  static Map getAll() {
    return _account;
  }

  static int getCount(Type) {
    if (_account[Type] == null) {
      _account[Type] = {};
    }
    if (_account[Type].keys == null) {
      return 0;
    }
    Save();
    return _account[Type].keys.length;
  }

  static void SetIndex(Index) {
    if (_account["index"] == null) {
      _account["index"] = 1;
    }

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

  static void Update() {
    _account = json.decode(_AccountFile.readAsStringSync());
  }
}
