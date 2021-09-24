import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/path.dart';

void main() async {
  await path().init();
  group('RPMLauncher Unit Test (http)', () {
    test('Check need for update', () async {
      bool Dev = (await Updater.checkForUpdate(VersionTypes.dev)).needUpdate;
      // bool Stable =
      //     (await Updater.checkForUpdate(VersionTypes.stable)).needUpdate;

      print("Stable channel ${Dev ? "need update" : "not need update"}");
      // print("Stable channel ${Stable ? "need update" : "not need update"}");

      /// 如果更新通道是 debug ，將不會更新，因此返回 false
      expect(
          (await Updater.checkForUpdate(VersionTypes.debug)).needUpdate, false);
    });
  });
}
