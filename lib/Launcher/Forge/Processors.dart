import 'dart:convert';
import 'dart:io';

import 'package:RPMLauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:RPMLauncher/Launcher/Forge/ForgeData.dart';
import 'package:RPMLauncher/Launcher/GameRepository.dart';
import 'package:RPMLauncher/Launcher/InstanceRepository.dart';
import 'package:RPMLauncher/Launcher/Libraries.dart';
import 'package:RPMLauncher/Utility/Config.dart';
import 'package:RPMLauncher/Utility/utility.dart';
import 'package:archive/archive.dart';
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
          ? json['outputs'].cast<String, String>()
          : null);

  Map<String, dynamic> toJson() => {
        'jar': jar,
        'classpath': classpath,
        'args': args,
        'outputs': outputs,
      };

  Future<void> Execution(String InstanceDirName, List<Library> libraries,
      String ForgeVersionID, String GameVersionID, ForgeDatas datas) async {
    Map InstanceConfig = InstanceRepository.getInstanceConfig(InstanceDirName);
    int JavaVersion = InstanceConfig['java_version'];
    File ProcessorJarFile = ForgeAPI.getLibFile(libraries, ForgeVersionID, jar);

    String ClassPathFiles =
        ProcessorJarFile.absolute.path + utility.getSeparator();

    classpath.forEach((lib) {
      ClassPathFiles +=
          "${ForgeAPI.getLibFile(libraries, ForgeVersionID, lib).absolute.path}${utility.getSeparator()}";
    });

    String? MainClass = utility.getJarMainClass(ProcessorJarFile);

    if (MainClass == null) {
      print("No MainClass found in " + jar); //如果找不到程式進入點
      return;
    } else {
      MainClass = MainClass.replaceAll(" ", "").replaceAll("\r", "");
    }
    List<String> args_ = [];

    args_.add("-cp");
    args_.add(ClassPathFiles); //處理器依賴項
    args_.add(MainClass); //程式進入點

    args.forEach((arguments) {
      if (utility.isSurrounded(arguments, "[", "]")) {
        //解析輸入參數有 [檔案名稱]
        String LibName =
            arguments.split("[").join("").split("]").join(""); //去除方括號
        arguments = ForgeAPI.getLibFile(libraries, ForgeVersionID, LibName)
            .absolute
            .path;
      } else if (utility.isSurrounded(arguments, "{", "}")) {
        //如果參數包含Forge資料的內容將進行替換
        String key = arguments.split("{").join("").split("}").join(""); //去除 {}

        if (key == "MINECRAFT_JAR") {
          arguments = GameRepository.getClientJar(GameVersionID)
              .absolute
              .path; //如果參數要求Minecraft Jar檔案則填入
        } else if (datas.forgeDatakeys.contains(key)) {
          ForgeData data = datas.forgeDatas[datas.forgeDatakeys.indexOf(key)];
          String clientData = data.Client;
          if (utility.isSurrounded(clientData, "[", "]")) {
            String DataPath =
                clientData.split("[").join("").split("]").join(""); //去除方括號
            List split_ = utility.split(DataPath, ":", max: 4);
            if (split_.length != 3 && split_.length != 4) print("err");

            String? extension_ = null;
            int last = split_.length - 1;
            List<String> splitted = split_[last].split("@");
            if (splitted.length == 2) {
              split_[last] = splitted[0];
              extension_ = splitted[1];
            } else if (splitted.length > 2) {
              print("err");
            }
            var group = split_[0].toString().replaceAll("\\", "/");
            var name = split_[1];
            var version = split_[2];
            var classifier = split_.length >= 4 ? split_[3] : null;
            var extension = extension_ == null ? "jar" : extension_;

            String fileName = name + "-" + version;
            if (classifier != null) fileName += "-" + classifier;
            fileName = fileName + "." + extension;
            var path = "${group.replaceAll(".", "/")}/$name/$version/$fileName";

            arguments = join(
                GameRepository.getLibraryRootDir(GameVersionID).absolute.path,
                path); //資料存放路徑
          } else if (clientData.startsWith("/")) {
            //例如 /data/client.lzma
            File InstallerFile = File(join(
                dataHome.absolute.path,
                "temp",
                "forge-installer",
                ForgeVersionID,
                "$ForgeVersionID-installer.jar"));
            final Archive archive =
                ZipDecoder().decodeBytes(InstallerFile.readAsBytesSync());
            for (final file in archive) {
              if (file.isFile &&
                  file.name.contains(clientData.replaceFirst("/", ""))) {
                final data = file.content as List<int>;
                File DataFile = File(join(
                    dataHome.absolute.path,
                    "temp",
                    "forge-installer",
                    ForgeVersionID,
                    file.name.replaceAll("/", Platform.pathSeparator)));
                DataFile.createSync(recursive: true);
                DataFile.writeAsBytesSync(data);
                arguments = DataFile.absolute.path;
                break;
              }
            }
          } else {}
        }
      } else if (utility.isSurrounded(arguments, "'", "'")) {}
      args_.add(arguments); //新增處理後的參數
    });
    //如果有輸出內容
    if (outputs != null) {
      // To do: 處理輸出的內容，目前看到的都是輸出雜湊值
    }

    Process? process = await Process.start(
        Config.GetValue("java_path_${JavaVersion}"), //Java Path
        args_,
        workingDirectory: InstanceRepository.DataHomeRootDir.absolute.path);

    String errorLog = "";
    // String runLog = "";
    // process.stdout.transform(utf8.decoder).listen((data) {
    //   runLog += data;
    // });
    process.stderr.transform(utf8.decoder).listen((data) {
      errorLog += data;
      print("$jar - error: $data");
    });
    process.exitCode.then((code) {
      print("$jar - Forge process is exited, exit code: $code");
      if (code != 0) {
        print(
            "$jar - An unknown error occurred while running the Forge process:\n$errorLog");
      }
      process = null;
    });
  }
}
