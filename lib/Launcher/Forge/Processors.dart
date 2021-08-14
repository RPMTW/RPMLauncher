import 'dart:convert';
import 'dart:io';

import 'package:RPMLauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:RPMLauncher/Launcher/GameRepository.dart';
import 'package:RPMLauncher/Launcher/InstanceRepository.dart';
import 'package:RPMLauncher/Launcher/Libraries.dart';
import 'package:RPMLauncher/Utility/Config.dart';
import 'package:RPMLauncher/Utility/utility.dart';
import 'package:path/path.dart';

import '../../path.dart';
import '../MinecraftClient.dart';

class Processors {
  final List<_Processor> processors;
  const Processors({
    required this.processors,
  });

  factory Processors.fromList(List processors) {
    List<_Processor> processors_ = [];
    processors.forEach(
        (processor) => processors_.add(_Processor.fromJson(processor)));
    return Processors(processors: processors_);
  }

  List<_Processor> toList() => processors;
}

class _Processor {
  final String jar;
  final List<String> classpath;
  final List<String> args;
  final Map<String, String>? outputs;

  const _Processor({
    required this.jar,
    required this.classpath,
    required this.args,
    this.outputs = null,
  });

  factory _Processor.fromJson(Map json) => _Processor(
      jar: json['jar'], classpath: json['classpath'], args: json['args']);

  Map<String, dynamic> toJson() => {
        'jar': jar,
        'classpath': classpath,
        'args': args,
      };

  Future<void> Execution(
      String InstanceDirName,
      List<Library> libraries,
      String ForgeVersionID,
      String GameVersionID,
      MinecraftClientHandler handler,
      SetState_) async {
    Map InstanceConfig = InstanceRepository.getInstanceConfig(InstanceDirName);
    int JavaVersion = InstanceConfig['java_version'];
    File ProcessorJarFile = ForgeAPI.getLibFile(libraries, ForgeVersionID, jar);

    late String ClassPathFiles;

    classpath.forEach((lib) {
      ClassPathFiles +=
          "${ForgeAPI.getLibFile(libraries, ForgeVersionID, lib).absolute.path}${utility.getSeparator()}";
    });

    print(ClassPathFiles);

    List<String> args_ = [
      "-jar", //執行Jar檔案
      ProcessorJarFile.absolute.path,
      "-cp",
      ClassPathFiles
    ];

    List<String> processorArgs = [];
    args.forEach((i) {
      if (i.startsWith("[") && i.endsWith("]")) {
        //需要下載檔案
        handler.TotalTaskLength++;
        final List info = ForgeAPI.ParseMaven(i);
        final String url = info[0];
        print(url);
        final FilePath = join(
            GameRepository.getLibraryRootDir(GameVersionID).absolute.path,
            info[1]);
        final FileName = info[2];
        handler.DownloadFile(url, FileName, FilePath, '', SetState_);
      }
      processorArgs.add(i);
    });
    print(processorArgs);

    args_.addAll(processorArgs); //將執行參數加入到args_

    Process? process = await Process.start(
        Config.GetValue("java_path_${JavaVersion}"), //Java Path
        args_,
        workingDirectory:
            InstanceRepository.getInstanceDir(InstanceDirName).absolute.path);

    String errorlog = "";
    process.stdout.transform(utf8.decoder).listen((data) {
      utility.onData.forEach((event) {
        print("Forge process log: $data");
      });
    });
    process.stderr.transform(utf8.decoder).listen((data) {
      //error
      utility.onData.forEach((event) {
        errorlog += data;
      });
    });
    process.exitCode.then((code) {
      process = null;
      print("Forge process is exited, exit code: $code");
      if (code != 0) {
        print(
            "An unknown error occurred while running the Forge process:\n$errorlog");
      }
    });
  }
}
