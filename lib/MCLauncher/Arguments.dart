import 'package:RPMLauncher/Utility/utility.dart';

class Arguments {
  List<String> ArgumentsDynamic(args, Variable, args_, VersionID) {
    if (ParseGameVersion(VersionID) >= 13) {
      //1.13+
      for (var jvm_i in args["jvm"]) {
        if (jvm_i.runtimeType == Map) {
          for (var rules_i in jvm_i["rules"]) {
            if (rules_i["os"]["name"] == utility.getOS()) {
              args_ = args + jvm_i["value"];
            }
            if (rules_i["os"].containsKey("version")) {
              if (rules_i["os"]["version"] == utility.getOS()) {
                args_ = args + jvm_i["value"];
              }
            }
          }
        } else {
          if (jvm_i.runtimeType == String && jvm_i.startsWith("-D")) {
            for (var i in Variable.keys) {
              if (jvm_i.contains(i)) {
                args_.add(jvm_i.replaceAll(i, Variable[i]));
              }
            }
          } else if (Variable.containsKey(jvm_i)) {
            args_.add(Variable[jvm_i] ?? "");
          }
        }
      }
      args_.add(args["mainClass"]);
      for (var game_i in args["game"]) {
        if (game_i.runtimeType == String && game_i.startsWith("--")) {
          args_.add(game_i);
        } else if (Variable.containsKey(game_i)) {
          args_.add(Variable[game_i] ?? "");
        }
      }
    } else {
      //1.8 -> 1.12
      args_.add(args["mainClass"]);
      args = args["game"].split(" ");
      for (var args_i = 0; args_i <= args.length - 1; args_i++) {
        var args_ii = args[args_i];
        if (args_ii.runtimeType == String && args_ii.startsWith("--")) {
          args_.add(args_ii);
        } else if (Variable.containsKey(args_ii)) {
          args_.add(Variable[args_ii] ?? "");
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
    }else{
      args_["game"] = Meta[ParseArgsName(VersionID)];
    }
    args_["mainClass"] = Meta["mainClass"];
    return args_;
  }
}
