import 'dart:io';

import 'package:dart_big5/big5.dart';
import 'package:rpmlauncher/launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/launcher/Forge/ForgeData.dart';
import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/model/Game/Libraries.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/util/Config.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmlauncher/util/Process.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/util/data.dart';

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
      // ?????? RPMLauncher ???????????????Forge?????????
      return;
    }

    int javaVersion = instanceConfig.javaVersion;
    File processorJarFile = ForgeAPI.getLibFile(libraries, jar);
    File installerFile = File(join(dataHome.absolute.path, "temp",
        "forge-installer", forgeVersionID, "$forgeVersionID-installer.jar"));

    String classPathFiles =
        processorJarFile.absolute.path + Util.getLibrarySeparator();

    await Future.forEach(classpath, (String lib) {
      classPathFiles +=
          "${ForgeAPI.getLibFile(libraries, lib).absolute.path}${Util.getLibrarySeparator()}";
    });

    String? mainClass = Util.getJarMainClass(processorJarFile);

    if (mainClass == null) {
      logger.error(ErrorType.io, "No MainClass found in $jar"); //??????????????????????????????
      return;
    } else {
      mainClass = mainClass
          .replaceAll(" ", "")
          .replaceAll("\n", "")
          .replaceAll("\t", "")
          .replaceAll("\r", "");
    }
    List<String> arguments = [];

    arguments.add("-cp");
    arguments.add(classPathFiles); //??????????????????
    arguments.add(mainClass); //???????????????

    await Future.forEach(args, (String _) {
      if (Util.isSurrounded(_, "[", "]")) {
        //????????????????????? [????????????]
        String libName = _.split("[").join("").split("]").join(""); //???????????????
        _ = ForgeAPI.getLibFile(libraries, libName).absolute.path;
      } else if (Util.isSurrounded(_, "{", "}")) {
        //??????????????????Forge??????????????????????????????
        String key = _.split("{").join("").split("}").join(""); //?????? {}

        if (key == "MINECRAFT_JAR") {
          _ = GameRepository.getClientJar(gameVersionID).absolute.path;
        } else if (key == "SIDE") {
          _ = "client";
        } else if (key == "MINECRAFT_VERSION") {
          _ = GameRepository.getClientJar(gameVersionID).absolute.path;
        } else if (key == "ROOT") {
          _ = dataHome.absolute.path;
        } else if (key == "INSTALLER") {
          _ = installerFile.absolute.path;
        } else if (key == "LIBRARY_DIR") {
          _ = GameRepository.getLibraryGlobalDir().absolute.path;
        } else if (dataList.forgeDataKeys.contains(key)) {
          ForgeData data =
              dataList.forgeDataList[dataList.forgeDataKeys.indexOf(key)];
          String clientData = data.client;
          if (Util.isSurrounded(clientData, "[", "]")) {
            String dataPath =
                clientData.split("[").join("").split("]").join(""); //???????????????
            List split_ = Util.split(dataPath, ":", max: 4);

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

            _ = join(GameRepository.getLibraryGlobalDir().absolute.path,
                path); //??????????????????
          } else if (clientData.startsWith("/")) {
            //?????? /data/client.lzma
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
                _ = dataFile.absolute.path;
                break;
              }
            }
          } else {}
        }
      } else if (Util.isSurrounded(_, "'", "'")) {}
      arguments.add(_); //????????????????????????
    });
    //?????????????????????
    if (outputs != null) {
      // TODO: ????????????????????????????????????????????????????????????
    }

    String exec =
        Config.getValue("java_path_16", defaultValue: "java_path_$javaVersion");

    await chmod(exec);

    logger.info("$jar - Forge process arguments: $exec ${arguments.join(" ")}");

    Process? process = await Process.start(exec, arguments,
        workingDirectory: dataHome.absolute.path);

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
