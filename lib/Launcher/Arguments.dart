import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Utility/Utility.dart';

class Arguments {
  static List<String> getVanilla(Map args, Map<String, String> variable,
      List<String> beforeArgs, Version comparableVersion,
      {ModLoader loader = ModLoader.vanilla}) {
    List<String> args_ = List<String>.from(beforeArgs);
    if (comparableVersion >= Version(1, 13, 0)) {
      //1.13-> 1.18+
      for (var jvmI in args["jvm"]) {
        if (jvmI is Map) {
          for (var rulesI in jvmI["rules"]) {
            if (rulesI["os"]["name"] == Uttily.getOS()) {
              args_.addAll((jvmI["value"] as List).cast<String>());
            }
            if (rulesI["os"].containsKey("version")) {
              if (rulesI["os"]["version"] == Uttily.getOS()) {
                args_.addAll((jvmI["value"] as List).cast<String>());
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
      args_.add(args["mainClass"]);
      for (var gameI in args["game"]) {
        if (variable.containsKey(gameI)) {
          args_.add(variable[gameI] ?? "");
        } else if (gameI is String &&
            (gameI.startsWith("--") || !gameI.contains("{"))) {
          args_.add(gameI);
        }
      }
    } else {
      //1.7.0 -> 1.12.2
      args_.add(args["mainClass"]);
      args = args["game"].split(" ");
      for (var argsI = 0; argsI <= args.length - 1; argsI++) {
        var argsIi = args[argsI];
        if (argsIi is String && argsIi.startsWith("--")) {
          args_.add(argsIi);
        } else if (variable.containsKey(argsIi)) {
          args_.add(variable[argsIi] ?? "");
        }
      }
    }
    return args_;
  }

  static List<String> getForge(Map args, Map<String, String> variable,
      List<String> args_, Version comparableVersion) {
    args_.addAll(getVanilla(args, variable, args_, comparableVersion,
        loader: ModLoader.forge));
    args_.add(args["mainClass"]);
    // print(args_);
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

  dynamic getArgsString(String versionID, MinecraftMeta meta) {
    late Map args_ = {};
    Version version = Uttily.parseMCComparableVersion(versionID);
    if (version >= Version(1, 13, 0)) {
      args_ = meta.rawMeta[parseArgsName(versionID)];
    } else {
      args_["game"] = meta.rawMeta[parseArgsName(versionID)];
    }
    args_["mainClass"] = meta.rawMeta["mainClass"];
    return args_;
  }
}
