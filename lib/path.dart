import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

 late final Directory dataHome;

class path {
  Future init() async {
    dataHome = Directory(join(
        (await getApplicationSupportDirectory()).absolute.path, "RPMLauncher"));
  }
}
