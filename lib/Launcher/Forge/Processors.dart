import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeData.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Libraries.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/main.dart';

class Processors {
  final List<Processor> processors;
  const Processors({
    required this.processors,
  });

  factory Processors.fromList(List processors) {
    List<Processor> processors_ = [];
    processors
        .forEach((processor) => processors_.add(Processor.fromJson(processor)));
    return Processors(processors: processors_);
  }

  List<Processor> toList() => processors;
}

class Processor {
  final String jar;
  final List<String> classpath;
  final List<String> args;
  final Map<String, String>? outputs;
  final List<String>? sides;

  const Processor({
    required this.jar,
    required this.classpath,
    required this.args,
    this.outputs,
    required this.sides,
  });

  factory Processor.fromJson(Map json) => Processor(
      jar: json['jar'],
      classpath: json['classpath'].cast<String>(),
      args: json['args'].cast<String>(),
      outputs: json.containsKey('outputs')
          ? json['outputs'].cast<String, String>()
          : null,
      sides: json.containsKey('sides') ? json['sides'].cast<String>() : null);

  Map<String, dynamic> toJson() => {
        'jar': jar,
        'classpath': classpath,
        'args': args,
        'outputs': outputs,
      };

  Future execution(String instanceDirName, List<Library> libraries,
      String forgeVersionID, String gameVersionID, ForgeDatas datas) async {
    if (sides != null &&
        sides!.contains("server") &&
        !sides!.contains("client")) {
      // 目前 RPMLauncher 只支援安裝客戶端
      return;
    }

    InstanceConfig instanceConfig =
        InstanceRepository.instanceConfig(instanceDirName);
    int javaVersion = instanceConfig.javaVersion;
    File processorJarFile = ForgeAPI.getLibFile(libraries, forgeVersionID, jar);
    File installerFile = File(join(dataHome.absolute.path, "temp",
        "forge-installer", forgeVersionID, "$forgeVersionID-installer.jar"));

    String classPathFiles =
        processorJarFile.absolute.path + Uttily.getSeparator();

    await Future.forEach(classpath, (String lib) {
      classPathFiles +=
          "${ForgeAPI.getLibFile(libraries, forgeVersionID, lib).absolute.path}${Uttily.getSeparator()}";
    });

    String? mainClass = Uttily.getJarMainClass(processorJarFile);

    if (mainClass == null) {
      logger.send("No MainClass found in " + jar); //如果找不到程式進入點
      return;
    } else {
      mainClass = mainClass
          .replaceAll(" ", "")
          .replaceAll("\n", "")
          .replaceAll("\t", "")
          .replaceAll("\r", "");
    }
    List<String> args_ = [];

    args_.add("-cp");
    args_.add(classPathFiles); //處理器依賴項
    args_.add(mainClass); //程式進入點

    await Future.forEach(args, (String arguments) {
      if (Uttily.isSurrounded(arguments, "[", "]")) {
        //解析輸入參數有 [檔案名稱]
        String libName =
            arguments.split("[").join("").split("]").join(""); //去除方括號
        arguments = ForgeAPI.getLibFile(libraries, forgeVersionID, libName)
            .absolute
            .path;
      } else if (Uttily.isSurrounded(arguments, "{", "}")) {
        //如果參數包含Forge資料的內容將進行替換
        String key = arguments.split("{").join("").split("}").join(""); //去除 {}

        if (key == "MINECRAFT_JAR") {
          arguments = GameRepository.getClientJar(gameVersionID).absolute.path;
        } else if (key == "SIDE") {
          arguments = "client";
        } else if (key == "MINECRAFT_VERSION") {
          arguments = GameRepository.getClientJar(gameVersionID).absolute.path;
        } else if (key == "ROOT") {
          arguments = dataHome.absolute.path;
        } else if (key == "INSTALLER") {
          arguments = installerFile.absolute.path;
        } else if (key == "LIBRARY_DIR") {
          arguments = GameRepository.getLibraryGlobalDir().absolute.path;
        } else if (datas.forgeDatakeys.contains(key)) {
          ForgeData data = datas.forgeDatas[datas.forgeDatakeys.indexOf(key)];
          String clientData = data.client;
          if (Uttily.isSurrounded(clientData, "[", "]")) {
            String dataPath =
                clientData.split("[").join("").split("]").join(""); //去除方括號
            List split_ = Uttily.split(dataPath, ":", max: 4);
            if (split_.length != 3 && split_.length != 4) logger.send("err");

            String? extension_;
            int last = split_.length - 1;
            List<String> splitted = split_[last].split("@");
            if (splitted.length == 2) {
              split_[last] = splitted[0];
              extension_ = splitted[1];
            } else if (splitted.length > 2) {
              logger.send("err");
            }
            String group = split_[0].toString().replaceAll("\\", "/");
            String name = split_[1];
            String version = split_[2];
            String? classifier = split_.length >= 4 ? split_[3] : null;
            String extension = extension_ ?? "jar";

            String fileName = name + "-" + version;
            if (classifier != null) fileName += "-" + classifier;
            fileName = fileName + "." + extension;
            var path = "${group.replaceAll(".", "/")}/$name/$version/$fileName";

            arguments = join(GameRepository.getLibraryGlobalDir().absolute.path,
                path); //資料存放路徑
          } else if (clientData.startsWith("/")) {
            //例如 /data/client.lzma
            final Archive archive =
                ZipDecoder().decodeBytes(installerFile.readAsBytesSync());
            for (final file in archive) {
              if (file.isFile &&
                  file.name.contains(clientData.replaceFirst("/", ""))) {
                final data = file.content as List<int>;
                File dataFile = File(join(
                    dataHome.absolute.path,
                    "temp",
                    "forge-installer",
                    forgeVersionID,
                    file.name.replaceAll("/", Platform.pathSeparator)));
                dataFile.createSync(recursive: true);
                dataFile.writeAsBytesSync(data);
                arguments = dataFile.absolute.path;
                break;
              }
            }
          } else {}
        }
      } else if (Uttily.isSurrounded(arguments, "'", "'")) {}
      args_.add(arguments); //新增處理後的參數
    });
    //如果有輸出內容
    if (outputs != null) {
      // To do: 處理輸出的內容，目前看到的都是輸出雜湊值
    }

    Process? process = await Process.start(
        Config.getValue("java_path_$javaVersion"), //Java Path
        args_,
        workingDirectory: InstanceRepository.dataHomeRootDir.absolute.path,
        runInShell: true);

    String errorLog = "";
    String runLog = "";
    try {
      process.stdout.transform(utf8.decoder).listen((data) {
        runLog += data;
      });
      process.stderr.transform(utf8.decoder).listen((data) {
        errorLog += data;
        logger.send("$jar - error: $data");
      });
    } catch (err) {}
    await process.exitCode.then((code) {
      logger.send("$jar - Forge process is exited, exit code: $code");
      if (code != 0) {
        logger.send(
            "$jar - An unknown error occurred while running the Forge process:\n$errorLog\n$runLog");
      }
      process = null;
    });
  }
}
