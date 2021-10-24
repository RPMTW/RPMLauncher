import 'package:rpmlauncher/Utility/Utility.dart';

class ForgeArgsHandler {
  List<String> get(args, Map variable, List<String> args_) {
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
        if (jvmI.runtimeType == String && jvmI.startsWith("-")) {
          for (var i in variable.keys) {
            if (jvmI.contains(i)) {
              // if(jvm_i.contains("DignoreList")) break;
              args_.add(jvmI.replaceAll(i, variable[i]));
            }
          }
        } else if (variable.containsKey(jvmI)) {
          args_.add(variable[jvmI] ?? "");
        }
      }
    }
    args_.add("-XX:+IgnoreUnrecognizedVMOptions");
    args_.add("--add-exports=java.base/sun.security.util=ALL-UNNAMED");
    args_.add("--add-exports=jdk.naming.dns/com.sun.jndi.dns=java.naming");
    args_.add("--add-opens=java.base/java.util.jar=ALL-UNNAMED");
    args_.add(args["mainClass"]);
    for (var gameI in args["game"]) {
      if (gameI.runtimeType == String) {
        args_.add(variable[gameI] ?? gameI);
      }
    }
    return args_;
  }
}
