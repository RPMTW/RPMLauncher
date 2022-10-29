import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/util/util.dart';
import '../script/test_helper.dart';

void main() async {
  setUpAll(() => TestHelper.init());

  group('Uttily Class -', () {
    test("Minecraft Version Parse", () {
      expect(Util.parseMCComparableVersion("1.18-pre1"), Version(1, 18, 0));
      expect(Util.parseMCComparableVersion("21w20a"), Version(1, 17, 0));
      expect(Util.parseMCComparableVersion("18w22c"), Version(1, 13, 0));
      expect(Util.parseMCComparableVersion("11w47a"), Version(1, 1, 0));
      expect(Util.parseMCComparableVersion("1.16.5-rc1"),
          Version(1, 16, 5, pre: "rc1"));
    });
    test("Check NetWork", () async {
      expect(await Util.hasNetWork(), true);
    });

    test("Get library separator", () async {
      expect(Util.getLibrarySeparator(), ":");
    }, skip: !(Platform.isLinux || Platform.isMacOS));
    test("Get library separator", () async {
      expect(Util.getLibrarySeparator(), ";");
    }, skip: !(Platform.isWindows));

    test("Linux file manager path", () async {
      expect(Util.getLinuxFileManager(), 'dolphin');
    }, skip: !(Platform.isLinux));
    test("Show file in file manager", () async {
      expect(
          await Util.openFolderAndSelectFile("${Platform.environment['HOME']}"),
          0);
    });
  });
}
