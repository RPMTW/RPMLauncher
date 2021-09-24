import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/path.dart';

void main() async {
  await path().init();
  group('RPMLauncher Unit Test (no http)', () {
    test('Check i18n', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await i18n.init();
      i18n.getLanguageCode();
      print(i18n.format('init.quick_setup.content'));
    });
    test('Check launcher info', () {
      print("Launcher Version: ${LauncherInfo.getVersion()}");
      print(
          "Launcher Version Type (i18n): ${Updater.toI18nString(LauncherInfo.getVersionType())}");
      print("Launcher Executing File: ${LauncherInfo.getExecutingFile()}");
    });
  });
}
