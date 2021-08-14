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
      jar: json['jar'],
      classpath: json['classpath'].cast<String>(),
      args: json['args'].cast<String>(),
      outputs: json.containsKey('outputs')
          ? json['outputs'].cast<Map<String, String>>()
          : null);

  Map<String, dynamic> toJson() => {
        'jar': jar,
        'classpath': classpath,
        'args': args,
        'outputs': outputs,
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

    String ClassPathFiles =
        ProcessorJarFile.absolute.path + utility.getSeparator();

    classpath.forEach((lib) {
      ClassPathFiles +=
          "${ForgeAPI.getLibFile(libraries, ForgeVersionID, lib).absolute.path}${utility.getSeparator()}";
    });

    print(ClassPathFiles);

    String? MainClass = utility.getJarMainClass(ProcessorJarFile);

    if (MainClass == null) {
      print("No MainClass found in " + jar); //如果找不到程式進入點
      return;
    }

    List<String> args_ = [
      "-cp",
      ClassPathFiles,
      MainClass
    ];

    List<String> processorArgs = [];
    args.forEach((i) {
      if (utility.isSurrounded(i, "[", "]")) {
        //解析輸入參數有 [檔案名稱]
        String LibName = i.split("[").join("").split("]").join(""); //去除方括號
        i = ForgeAPI.getLibFile(libraries, ForgeVersionID, LibName)
            .absolute
            .path;
      } else if (utility.isSurrounded(i, "{", "}")) {
        //如果參數包含Forge資料的內容將進行替換
        String key = i.split("{").join("").split("}").join(""); //去除 {}

        if (key == "MINECRAFT_JAR") {
          i = GameRepository.getClientJar(GameVersionID)
              .absolute
              .path; //如果參數要求Minecraft Jar檔案則填入
        } else {
          // To do: 處理其他例外
        }
      } else if (utility.isSurrounded(i, "'", "'")) {}
      processorArgs.add(i);
    });
    print(processorArgs);

    //將執行參數加入到args_
    args_.addAll(processorArgs);

    //如果有輸出內容
    if (outputs != null) {
      // To do: 處理輸出的內容，目前看到的都是輸出雜湊值
    }

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
