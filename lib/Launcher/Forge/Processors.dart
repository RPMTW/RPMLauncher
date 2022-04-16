import 'dart:io';

import 'package:dart_big5/big5.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeData.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Game/Libraries.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Logger.dart';
import 'package:rpmlauncher/Utility/Process.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/Data.dart';

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

  Future execution(
      InstanceConfig instanceConfig,
      List<Library> libraries,
      String forgeVersionID,
      String gameVersionID,
      ForgeDataList dataList) async {
    if (sides != null &&
        sides!.contains("server") &&
        !sides!.contains("client")) {
      // 目前 RPMLauncher 只支援安裝Forge客戶端
      return;
    }

    int javaVersion = instanceConfig.javaVersion;
    File processorJarFile = ForgeAPI.getLibFile(libraries, jar);
    File installerFile = File(join(dataHome.absolute.path, "temp",
        "forge-installer", forgeVersionID, "$forgeVersionID-installer.jar"));

    String classPathFiles =
        processorJarFile.absolute.path + Uttily.getLibrarySeparator();

    await Future.forEach(classpath, (String lib) {
      classPathFiles +=
          "${ForgeAPI.getLibFile(libraries, lib).absolute.path}${Uttily.getLibrarySeparator()}";
    });

    String? mainClass = Uttily.getJarMainClass(processorJarFile);

    if (mainClass == null) {
      logger.error(ErrorType.io, "No MainClass found in $jar"); //如果找不到程式進入點
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
    args_.add(classPathFiles); //處理器函式庫
    args_.add(mainClass); //程式進入點

    await Future.forEach(args, (String arguments) {
      if (Uttily.isSurrounded(arguments, "[", "]")) {
        //解析輸入參數有 [檔案名稱]
        String libName =
            arguments.split("[").join("").split("]").join(""); //去除方括號
        arguments = ForgeAPI.getLibFile(libraries, libName).absolute.path;
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
        } else if (dataList.forgeDataKeys.contains(key)) {
          ForgeData data =
              dataList.forgeDataList[dataList.forgeDataKeys.indexOf(key)];
          String clientData = data.client;
          if (Uttily.isSurrounded(clientData, "[", "]")) {
            String dataPath =
                clientData.split("[").join("").split("]").join(""); //去除方括號
            List split_ = Uttily.split(dataPath, ":", max: 4);

            String? extension_;
            int last = split_.length - 1;
            List<String> split = split_[last].split("@");
            if (split.length == 2) {
              split_[last] = split[0];
              extension_ = split[1];
            }

            String group = split_[0].toString().replaceAll("\\", "/");
            String name = split_[1];
            String version = split_[2];
            String? classifier = split_.length >= 4 ? split_[3] : null;
            String extension = extension_ ?? "jar";

            String fileName = "$name-$version";
            if (classifier != null) fileName += "-$classifier";
            fileName = "$fileName.$extension";
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
      // TODO: 處理輸出的內容，目前看到的都是輸出雜湊值
    }

    String exec =
        Config.getValue("java_path_16", defaultValue: "java_path_$javaVersion");

    await chmod(exec);

    logger.info("$jar - Forge process arguments: $exec ${args_.join(" ")}");

    Process? process = await Process.start(exec, args_,
        workingDirectory: InstanceRepository.dataHomeRootDir.absolute.path,
        runInShell: true);

    String errorLog = "";
    String runLog = "";
    try {
      process.stdout.listen((data) {
        String string = big5.decode(data);
        runLog += string;
      });
      process.stderr.listen((data) {
        String string = big5.decode(data);
        errorLog += string;
        logger.info("$jar - error: $string");
      });
    } catch (err) {}
    await process.exitCode.then((code) {
      logger.info("$jar - Forge process is exited, exit code: $code");
      if (code != 0) {
        logger.info(
            "$jar - An unknown error occurred while running the Forge process:\n$errorLog\n$runLog");
      }
      process = null;
    });
  }
}
