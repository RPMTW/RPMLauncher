import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpmlauncher/util/launcher_path.dart';

void main() {
  test('old data home (for windows, macOS)', () async {
    Directory oldHome = Directory(join(
        (await getApplicationDocumentsDirectory()).path,
        'RPMLauncher',
        'data'));

    oldHome.createSync(recursive: true);

    await LauncherPath.init();
    Directory path = LauncherPath.currentDataHome;
    expect(path.path, oldHome.path);
  }, skip: Platform.isLinux);

  test('old data home (for linux)', () async {
    Directory oldHome = Directory(
        join(absolute(Platform.environment['HOME']!), 'RPMLauncher', 'data'));

    oldHome.createSync(recursive: true);

    await LauncherPath.init();
    Directory path = LauncherPath.currentDataHome;
    expect(path.path, oldHome.path);
  }, skip: !Platform.isLinux);
}
