import 'dart:io';

import 'package:crypto/crypto.dart';

class CheckData {
  static bool checkSha1Sync(FileSystemEntity file, String sha1Hash) {
    if (sha1.convert(File(file.path).readAsBytesSync()).toString() ==
        sha1Hash.toString()) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> checkSha1(FileSystemEntity file, String sha1Hash) async {
    if (sha1.convert(await File(file.path).readAsBytes()).toString() ==
        sha1Hash.toString()) {
      return true;
    } else {
      return false;
    }
  }
}
