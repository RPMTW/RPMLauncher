import 'dart:convert';

import 'package:rpmlauncher/Utility/utility.dart';

class ForgeArgsHandler {

  List<String> Get(args, Map Variable, List<String> args_) {
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
        if (jvm_i.runtimeType == String && jvm_i.startsWith("-")) {
          for (var i in Variable.keys) {
            if (jvm_i.contains(i)) {
              // if(jvm_i.contains("DignoreList")) break;
              args_.add(jvm_i.replaceAll(i, Variable[i]));
            }
          }
        } else if (Variable.containsKey(jvm_i)) {
          args_.add(Variable[jvm_i] ?? "");
        }
      }
    }
    args_.add("--add-modules");
    args_.add("ALL-MODULE-PATH");
    args_.add("--add-opens");
    args_.add("java.base/java.util.jar=cpw.mods.securejarhandler");
    args_.add("--add-exports");
    args_.add("java.base/sun.security.util=cpw.mods.securejarhandler");
    args_.add("--add-exports");
    args_.add("jdk.naming.dns/com.sun.jndi.dns=java.naming");
    args_.add(args["mainClass"]);
    for (var game_i in args["game"]) {
      if (game_i.runtimeType == String && game_i.startsWith("--")) {
        args_.add(game_i);
      } else if (Variable.containsKey(game_i)) {
        args_.add(Variable[game_i] ?? "");
      }
    }
    print(args_);
    return args_;
  }
}
