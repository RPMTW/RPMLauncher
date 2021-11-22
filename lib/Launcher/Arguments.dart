import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Utility/Utility.dart';

class Arguments {
  List<String> argumentsDynamic(
      args, variable, args_, Version comparableVersion) {
    if (comparableVersion >= Version(1, 13, 0)) {
      //1.13-> 1.18+
      for (var jvmI in args["jvm"]) {
        if (jvmI.runtimeType == Map) {
          for (var rulesI in jvmI["rules"]) {
            if (rulesI["os"]["name"] == Uttily.getOS()) {
              args_ = args + jvmI["value"];
            }
            if (rulesI["os"].containsKey("version")) {
              if (rulesI["os"]["version"] == Uttily.getOS()) {
                args_ = args + jvmI["value"];
              }
            }
          }
        } else {
          if (jvmI.runtimeType == String && jvmI.startsWith("-D")) {
            for (var i in variable.keys) {
              if (jvmI.contains(i)) {
                args_.add(jvmI.replaceAll(i, variable[i]));
              }
            }
          } else if (variable.containsKey(jvmI)) {
            args_.add(variable[jvmI] ?? "");
          }
        }
      }
      args_.add(args["mainClass"]);
      for (var gameI in args["game"]) {
        if (gameI.runtimeType == String && gameI.startsWith("--")) {
          args_.add(gameI);
        } else if (variable.containsKey(gameI)) {
          args_.add(variable[gameI] ?? "");
        }
      }
    } else {
      //1.7.0 -> 1.12.2
      args_.add(args["mainClass"]);
      args = args["game"].split(" ");
      for (var argsI = 0; argsI <= args.length - 1; argsI++) {
        var argsIi = args[argsI];
        if (argsIi.runtimeType == String && argsIi.startsWith("--")) {
          args_.add(argsIi);
        } else if (variable.containsKey(argsIi)) {
          args_.add(variable[argsIi] ?? "");
        }
      }
    }
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
    if (Uttily.parseMCComparableVersion(versionID) >= Version(1, 13, 0)) {
      args_ = meta.rawMeta[parseArgsName(versionID)];
    } else {
      args_["game"] = meta.rawMeta[parseArgsName(versionID)];
    }
    args_["mainClass"] = meta.rawMeta["mainClass"];
    return args_;
  }
}
