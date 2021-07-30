import 'package:crypto/crypto.dart';
import 'package:rpmlauncher/Screen/Log.dart';

class CheckData {
  bool Assets(File, Sha1Hash) {
    if (sha1.convert(File.readAsBytesSync()).toString() ==
        Sha1Hash.toString()) {
      return true;
    } else {
      return false;
    }
  }


}