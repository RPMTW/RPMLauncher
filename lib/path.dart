import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

late var dataHome = Directory("");

init() async {
  dataHome = Directory(join(await getData(), "RPMLauncher"));
}

Future<String> getData() async {
  Directory appDocDir = await getApplicationSupportDirectory();
  return appDocDir.absolute.path;
}
