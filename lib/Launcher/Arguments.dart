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
              String arg = jvmI;
              key.forEach((key) => arg = arg.replaceAll(key, variable[key]!));
              args_.add(arg);
            } else {
              args_.add(jvmI);
            }
          }
        }
      }
    }
    args_.add(args["mainClass"]);
    if (args["game"] != null) {
      for (var gameI in args["game"]) {
        if (variable.containsKey(gameI)) {
          args_.add(variable[gameI] ?? "");
        } else if (gameI is String &&
            (gameI.startsWith("--") || !gameI.contains("{"))) {
          args_.add(gameI);
        }
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

  Map getArgsString(String versionID, MinecraftMeta meta) {
    Map args_ = {};
    Version version = Uttily.parseMCComparableVersion(versionID);
    if (version >= Version(1, 13, 0)) {
      args_.addAll(meta['arguments']);
    } else {
      args_["game"] = meta['minecraftArguments'].toString().split(" ");
    }
    args_["mainClass"] = meta["mainClass"];

    if (meta.containsKey('logging')) {
      args_["logging"] = meta['logging'];
    }
    return args_;
  }
}
