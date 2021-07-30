import 'dart:io';

class Arguments {
  List<String> ArgumentsDynamic(args, Variable, args_) {
    if (args.runtimeType != String) { //1.13+
      for (var jvm_i in args["jvm"]) {
        if (jvm_i.runtimeType == Map) {
          for (var rules_i in jvm_i["rules"]) {
            if (rules_i["os"]["name"] == Platform.operatingSystem) {
              args_ = args + jvm_i["value"];
            }
            if (rules_i["os"].containsKey("version")) {
              if (rules_i["os"]["version"] == Platform.operatingSystemVersion) {
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
      args_.add("net.minecraft.client.main.Main");
      for (var game_i in args["game"]) {
        if (game_i.runtimeType == String && game_i.startsWith("--")) {
          args_.add(game_i);
        } else if (Variable.containsKey(game_i)) {
          args_.add(Variable[game_i] ?? "");
        }
      }
    }else{ //1.8 -> 1.12
      args_.add("net.minecraft.client.main.Main");
      for (var args_i = 0; args_i <= args.split(" ").length - 1; args_i++) {
       var args_a = args.split(" ");
        var args_ii = args_a[args_i];
       if (args_ii.runtimeType == String && args_ii.startsWith("--")) {
          args_.add(args_ii);
        } else if (Variable.containsKey(args_ii)) {
          args_.add(Variable[args_ii] ?? "");
        }
      }
    }
    return args_;
  }

  String ParseVersion(Data) {
    var ArgumentsName;
    if (Data["arguments"] == null) {//1.8 -> 1.12 Version
      ArgumentsName = "minecraftArguments";
    } else {
      ArgumentsName = "arguments"; //1.13+
    }

    return ArgumentsName;
  }
}
