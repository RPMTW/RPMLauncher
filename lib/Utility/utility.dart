import 'dart:io';
class utility{

  OpenFileManager(Dir) async {
    if (Platform.isLinux) {
      await Process.run("xdg-open", [Dir]);
    } else if (Platform.isWindows) {
      await Process.run("start", [Dir], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run("open", [Dir]);
    }
  }

}