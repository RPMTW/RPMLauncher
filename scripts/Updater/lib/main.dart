// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:io';
import 'dart:core';
import 'package:args/args.dart';
import 'package:path/path.dart';

void main(List<String> args) async {
  var parser = ArgParser();

  parser.addFlag('file_path');
  parser.addFlag('export_path');

  var results = parser.parse(args);

  Directory FilePath = Directory(results.rest[0]);
  Directory ExportPath = Directory(results.rest[1]);
  await copyDirectory(FilePath, ExportPath);

  if (Platform.isWindows) {
    String exe = join(ExportPath.absolute.path, "rpmlauncher.exe");
    Process.run(exe, []);
  } else if (Platform.isMacOS) {
    //目前尚未支援MacOS
  } else if (Platform.isLinux) {
    String exe = join(ExportPath.absolute.path, "RPMLauncher");
    // Process.run('chmod', ['-R', '777', exe]);
    Process.run(exe, []);
  }
  print("更新完畢");
}

Future<void> copyDirectory(Directory source, Directory destination) async {
  await source.list(recursive: false).forEach((FileSystemEntity entity) {
    if (entity is Directory) {
      var newDirectory =
          Directory(join(destination.absolute.path, basename(entity.path)));
      newDirectory.createSync(recursive: true);
      copyDirectory(entity.absolute, newDirectory);
    } else if (entity is File) {
      entity.copySync(join(destination.path, basename(entity.path)));
    }
  });
}
