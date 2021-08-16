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
    args_.add("-XX:+IgnoreUnrecognizedVMOptions");
    args_.add("--add-exports=java.base/sun.security.util=ALL-UNNAMED");
    args_.add("--add-exports=jdk.naming.dns/com.sun.jndi.dns=java.naming");
    args_.add("--add-opens=java.base/java.util.jar=ALL-UNNAMED");
    args_.add(args["mainClass"]);
    for (var game_i in args["game"]) {
      if (game_i.runtimeType == String) {
        args_.add(Variable[game_i] ?? game_i);
      }
    }
    return args_;
  }
}
