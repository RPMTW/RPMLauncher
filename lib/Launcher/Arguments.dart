import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Utility/Utility.dart';

class Arguments {
  static List<String> getVanilla(
      Map args, Map<String, String> variable, Version comparableVersion) {
    List<String> args_ = [];
    if (args["jvm"] != null) {
      for (var jvmI in args["jvm"]) {
        if (jvmI is Map) {
          for (var rulesI in jvmI["rules"]) {
            List<String> value = [];
            if (jvmI["value"] is List) {
              value = jvmI["value"].cast<String>();
            } else if (jvmI["value"] is String) {
              value = [jvmI["value"]];
            }

            if (rulesI["os"]["name"] == Uttily.getMinecraftFormatOS()) {
              args_.addAll(value);
            } else if (rulesI["os"].containsKey("version")) {
              if (rulesI["os"]["version"] == Uttily.getMinecraftFormatOS()) {
                args_.addAll(value);
              }
            }
          }
        } else {
          if (variable.containsKey(jvmI)) {
            args_.add(variable[jvmI]!);
          } else if (jvmI is String) {
            List<String> key = variable.keys
                .where(
                  (element) => jvmI.contains(element),
                )
                .toList();

            if (key.isNotEmpty) {
              String _arg = jvmI;
              key.forEach(
                  (_key) => _arg = _arg.replaceAll(_key, variable[_key]!));
              args_.add(_arg);
            } else {
              args_.add(jvmI);
            }
          }
        }
      }
    }
    args_.add(args["mainClass"]);
    for (var gameI in args["game"]) {
      if (variable.containsKey(gameI)) {
        args_.add(variable[gameI] ?? "");
      } else if (gameI is String &&
          (gameI.startsWith("--") || !gameI.contains("{"))) {
        args_.add(gameI);
      }
    }
    return args_;
  }

  static List<String> getForge(
      Map args, Map<String, String> variable, Version comparableVersion) {
    List<String> args_ = [];
    args_.addAll(getVanilla(args, variable, comparableVersion));
    args_.add(args["mainClass"]);
    return args_;
  }

  String parseArgsName(String versionID) {
    String argumentsName;
    /*
    1.13+ 格式
     */
    if (Uttily.parseMCComparableVersion(versionID) >= Version(1, 13, 0)) {
      argumentsName = "arguments";
    } else {
      argumentsName = "minecraftArguments";
    }
    return argumentsName;
  }

  Map getArgsString(String versionID, MinecraftMeta meta) {
    Map args_ = {};
    Version version = Uttily.parseMCComparableVersion(versionID);
    if (version >= Version(1, 13, 0)) {
      args_ = meta.rawMeta[parseArgsName(versionID)];
    } else {
      args_["game"] =
          meta.rawMeta[parseArgsName(versionID)].toString().split(" ");
    }
    args_["mainClass"] = meta.rawMeta["mainClass"];
    return args_;
  }
}
