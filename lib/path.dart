import 'package:path/path.dart';
import 'dart:io';
late var home;
_getData(){
  Map<String, String> envVars = Platform.environment;
   if (Platform.isLinux) {
    home = envVars['HOME'];
    return Directory(join(home,".local","share"));
   }else if (Platform.isMacOS) {
    home = envVars['HOME'];
  }else  if (Platform.isWindows) {
    home = envVars['UserProfile'];
    return Directory(join(home,"AppData","Roaming"));

   }
}
_getConfig(){
  Map<String, String> envVars = Platform.environment;
  if (Platform.isLinux) {
    home = envVars['HOME'];
    return Directory(join(home,".config"));
  }else if (Platform.isMacOS) {
    home = envVars['HOME'];
  }else  if (Platform.isWindows) {
    home = envVars['UserProfile'];
    return Directory(join(home,"AppData","Local"));

  }
}
var dataHome=_getData();
var configHome=_getConfig();
