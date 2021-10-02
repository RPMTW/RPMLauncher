// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:io';

import 'package:crypto/crypto.dart';

class CheckData {
  static bool CheckSha1Sync(FileSystemEntity file, String Sha1Hash) {
    if (sha1.convert(File(file.path).readAsBytesSync()).toString() ==
        Sha1Hash.toString()) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> CheckSha1(FileSystemEntity file, String Sha1Hash) async {
    if (sha1.convert(await File(file.path).readAsBytes()).toString() ==
        Sha1Hash.toString()) {
      return true;
    } else {
      return false;
    }
  }
}
