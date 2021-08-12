import 'dart:io';

import 'package:crypto/crypto.dart';

class CheckData {
  bool CheckSha1Sync(FileSystemEntity file, Sha1Hash) {
    if (sha1.convert(File(file.path).readAsBytesSync()).toString() ==
        Sha1Hash.toString()) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> CheckSha1(FileSystemEntity file, Sha1Hash) async {
    if (sha1.convert(await File(file.path).readAsBytes()).toString() ==
        Sha1Hash.toString()) {
      return true;
    } else {
      return false;
    }
  }
}
