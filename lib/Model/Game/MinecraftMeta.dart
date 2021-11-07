import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/main.dart';

class MinecraftMeta {
  late Version comparableVersion;

  Map<String, dynamic> rawMeta;

  MinecraftMeta(this.rawMeta) {
    String _version = rawMeta['id'];

    try {
      comparableVersion = Version.parse(_version);
    } catch (e) {
      /// 例如 21w44a
      if (RegExp(r'(?:(?<yy>\d\d)w(?<ww>\d\d)[a-z])').hasMatch(_version)) {
        try {
          comparableVersion = Version.parse(rawMeta['assets']);
        } catch (e) {
          logger.error(ErrorType.data, "Minecraft 可比較版本號解析失敗",
              stackTrace: StackTrace.current);
          comparableVersion = Version.none;
        }
      } else {
        comparableVersion = Version.none;
      }
    }
  }

  operator [](String key) => rawMeta[key];
  operator []=(String key, dynamic value) => rawMeta[key] = value;

  bool containsKey(String key) => rawMeta.containsKey(key);
}
