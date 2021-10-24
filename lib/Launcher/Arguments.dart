import 'package:rpmlauncher/Utility/Utility.dart';

class Arguments {
  List<String> argumentsDynamic(args, variable, args_, versionID) {
    if (parseGameVersion(versionID) >= 13) {
      //1.13+
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
      //1.8 -> 1.12
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

  String parseArgsName(versionID) {
    String argumentsName;
    /*
    13 -> 1.13+
     */
    if (parseGameVersion(versionID) >= 13) {
      argumentsName = "arguments";
    } else {
      argumentsName = "minecraftArguments";
    }
    return argumentsName;
  }

  double parseGameVersion(versionID) {
    /*
    ex: 1.17 -> 17
        1.8.9 > 8.9
        1.16.5 -> 16.5
     */
    versionID = double.parse(versionID.toString().split("1.").join(""));
    return versionID;
  }

  dynamic getArgsString(versionID, Map meta) {
    late Map args_ = {};
    if (parseGameVersion(versionID) >= 13) {
      args_ = meta[parseArgsName(versionID)];
    } else {
      args_["game"] = meta[parseArgsName(versionID)];
    }
    args_["mainClass"] = meta["mainClass"];
    return args_;
  }
}
