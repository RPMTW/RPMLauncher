import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import '../TestUttily.dart';

void main() async {
  setUpAll(() => TestUttily.init());

  group('Uttily Class -', () {
    test("Minecraft Version Parse", () {
      expect(Uttily.parseMCComparableVersion("1.18-pre1"), Version(1, 18, 0));
      expect(Uttily.parseMCComparableVersion("21w20a"), Version(1, 17, 0));
      expect(Uttily.parseMCComparableVersion("18w22c"), Version(1, 13, 0));
      expect(Uttily.parseMCComparableVersion("11w47a"), Version(1, 1, 0));
      expect(Uttily.parseMCComparableVersion("1.16.5-rc1"),
          Version(1, 16, 5, pre: "rc1"));
    });
    test("Check NetWork", () async {
      expect(await Uttily.hasNetWork(), true);
    });
  });
}
