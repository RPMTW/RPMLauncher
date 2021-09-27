// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'package:rpmlauncher/Utility/utility.dart';

class Arguments {
  List<String> ArgumentsDynamic(args, Variable, args_, VersionID) {
    if (ParseGameVersion(VersionID) >= 13) {
      //1.13+
      for (var jvmI in args["jvm"]) {
        if (jvmI.runtimeType == Map) {
          for (var rulesI in jvmI["rules"]) {
            if (rulesI["os"]["name"] == utility.getOS()) {
              args_ = args + jvmI["value"];
            }
            if (rulesI["os"].containsKey("version")) {
              if (rulesI["os"]["version"] == utility.getOS()) {
                args_ = args + jvmI["value"];
              }
            }
          }
        } else {
          if (jvmI.runtimeType == String && jvmI.startsWith("-D")) {
            for (var i in Variable.keys) {
              if (jvmI.contains(i)) {
                args_.add(jvmI.replaceAll(i, Variable[i]));
              }
            }
          } else if (Variable.containsKey(jvmI)) {
            args_.add(Variable[jvmI] ?? "");
          }
        }
      }
      args_.add(args["mainClass"]);
      for (var gameI in args["game"]) {
        if (gameI.runtimeType == String && gameI.startsWith("--")) {
          args_.add(gameI);
        } else if (Variable.containsKey(gameI)) {
          args_.add(Variable[gameI] ?? "");
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
        } else if (Variable.containsKey(argsIi)) {
          args_.add(Variable[argsIi] ?? "");
        }
      }
    }
    return args_;
  }

  String ParseArgsName(VersionID) {
    var ArgumentsName;
    /*
    13 -> 1.13+
     */
    if (ParseGameVersion(VersionID) >= 13) {
      ArgumentsName = "arguments";
    } else {
      ArgumentsName = "minecraftArguments";
    }
    return ArgumentsName;
  }

  double ParseGameVersion(VersionID) {
    /*
    ex: 1.17 -> 17
        1.8.9 > 8.9
        1.16.5 -> 16.5
     */
    VersionID = double.parse(VersionID.toString().split("1.").join(""));
    return VersionID;
  }

  dynamic GetArgsString(VersionID, Meta) {
    late Map args_ = {};
    if (ParseGameVersion(VersionID) >= 13) {
      args_ = Meta[ParseArgsName(VersionID)];
    } else {
      args_["game"] = Meta[ParseArgsName(VersionID)];
    }
    args_["mainClass"] = Meta["mainClass"];
    return args_;
  }
}
