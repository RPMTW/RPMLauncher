import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Launcher/Arguments.dart';
import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Launcher/Forge/ArgsHandler.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/GameCrash.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../LauncherInfo.dart';
import '../main.dart';
import '../path.dart';

class LogScreen_ extends State<LogScreen> {
  late var InstanceDirName;

  LogScreen_(instance_folder_) {
    InstanceDirName = instance_folder_;
  }

  String log_ = "";
  String errorLog_ = "";
  var LogTimer;
  late File ConfigFile;
  late File AccountFile;
  late var InstanceConfig;
  late Directory InstanceDir;
  late ScrollController _scrollController;
  late var config;
  var process;
  late var BContext;
  final int MaxLogLength = Config.GetValue("max_log_length");
  late bool ShowLog;
  bool scrolling = true;

  void initState() {
    Directory DataHome = dataHome;
    InstanceDir = InstanceRepository.getInstanceDir(InstanceDirName);
    InstanceConfig = json.decode(
        InstanceRepository.getInstanceConfigFile(InstanceDirName)
            .readAsStringSync());
    config = json.decode(GameRepository.getConfigFile().readAsStringSync());
    var VersionID = InstanceConfig["version"];
    var Loader = InstanceConfig["loader"];
    var args = json.decode(
        GameRepository.getArgsFile(VersionID, Loader).readAsStringSync());

    var PlayerName =
        account.getByIndex(account.GetType(), account.GetIndex())["UserName"];
    var ClientJar = GameRepository.getClientJar(VersionID).absolute.path;
    var Natives = GameRepository.getNativesDir(VersionID).absolute.path;

    var MinRam = 512;
    var MaxRam =
        InstanceConfig['java_max_ram'] ?? Config.GetValue("java_max_ram");
    var Width = Config.GetValue("game_width");
    var Height = Config.GetValue("game_height");

    late var LibraryFiles;
    var LibraryDir = GameRepository.getLibraryRootDir(VersionID)
        .listSync(recursive: true, followLinks: true);
    LibraryFiles = ClientJar + utility.getSeparator();
    for (var i in LibraryDir) {
      if (i.runtimeType.toString() == "_File") {
        LibraryFiles += "${i.absolute.path}${utility.getSeparator()}";
      }
    }

    ShowLog = Config.GetValue("show_log");

    _scrollController = new ScrollController(
      keepScrollOffset: true,
    );
    start(
        args,
        Loader,
        ClientJar,
        MinRam,
        MaxRam,
        Natives,
        LauncherInfo().GetVersion(),
        LibraryFiles,
        PlayerName,
        "RPMLauncher_${VersionID}",
        InstanceDir.absolute.path,
        join(DataHome.absolute.path, "assets"),
        VersionID,
        account.getByIndex(account.GetType(), account.GetIndex())["UUID"],
        account.getByIndex(
            account.GetType(), account.GetIndex())["AccessToken"],
        account.GetType(),
        Width,
        Height);
    super.initState();
    setState(() {});
  }

  start(
      args,
      Loader,
      ClientJar,
      MinRam,
      MaxRam,
      Natives,
      LauncherVersion,
      ClassPath,
      PlayerName,
      LauncherVersionID,
      GameDir,
      AssetsDirRoot,
      GameVersionID,
      UUID,
      Token,
      AuthType,
      Width,
      Height) async {
    var Variable = {
      r"${auth_player_name}": PlayerName,
      r"${version_name}": LauncherVersionID,
      r"${game_directory}": GameDir,
      r"${assets_root}": AssetsDirRoot,
      r"${assets_index_name}": GameVersionID,
      r"${auth_uuid}": UUID,
      r"${auth_access_token}": Token,
      r"${user_type}": AuthType,
      r"${version_type}": "RPMLauncher_${LauncherVersion}",
      r"${natives_directory}": Natives,
      r"${launcher_name}": "RPMLauncher",
      r"${launcher_version}": LauncherVersion
    };
    List<String> args_ = [
      "-Dminecraft.client.jar=${ClientJar}", //Client Jar
      "-Xmn${MinRam}m", //最小記憶體
      "-Xmx${MaxRam}m", //最大記憶體
      "-Djava.library.path=${Natives}",
      "-cp",
      ClassPath,
    ];
    args_.addAll(InstanceConfig['java_jvm_args'] ??
        Config.GetValue('java_jvm_args').cast<String>());

    List<String> GameArgs_ = [
      "--width",
      Width.toString(),
      "--height",
      Height.toString()
    ];

    if (Loader == ModLoader().Fabric || Loader == ModLoader().None) {
      args_ =
          Arguments().ArgumentsDynamic(args, Variable, args_, GameVersionID);
    } else if (Loader == ModLoader().Forge) {
      /*
      目前仍然無法啟動Forge
       */
      args_ = ForgeArgsHandler().Get(args, Variable, args_);
    }
    args_.addAll(GameArgs_);
    int JavaVersion = InstanceConfig["java_version"];
    this.process = await Process.start(
        InstanceConfig["java_path_${JavaVersion}"] ??
            config["java_path_${JavaVersion}"], //Java Path
        args_,
        workingDirectory: GameDir,
        environment: {'APPDATA': dataHome.absolute.path});

    setState(() {});
    this.process.stdout.transform(utf8.decoder).listen((data) {
      utility.onData.forEach((event) {
        if (ShowLog) {
          log_ += data;
          setState(() {});
        }
      });
    });
    this.process.stderr.transform(utf8.decoder).listen((data) {
      //error
      utility.onData.forEach((event) {
        errorLog_ += data;
      });
    });
    this.process.exitCode.then((code) {
      process = null;
      InstanceConfig["last_play"] = DateTime.now().millisecondsSinceEpoch;
      InstanceRepository.getInstanceConfigFile(InstanceDirName)
          .writeAsStringSync(json.encode(InstanceConfig));
      if (code != 0) {
        //1.17離開遊戲的時候會有退出代碼 -1
        if (code == -1 && Arguments().ParseGameVersion(GameVersionID) >= 17)
          return;
        showDialog(
          context: BContext,
          builder: (BContext) => GameCrash(code.toString(), errorLog_),
        );
      }
    });
    const oneSec = const Duration(seconds: 1);
    LogTimer = new Timer.periodic(oneSec, (timer) {
      InstanceConfig["play_time"] =
          InstanceConfig["play_time"] + Duration(seconds: 1).inMilliseconds;
      if (ShowLog) {
        if (log_.split("\n").length > MaxLogLength) {
          //delete log
          List LogList = log_.split("\n");
          LogList =
              LogList.getRange(LogList.length - MaxLogLength, LogList.length)
                  .toList();
          log_ = LogList.join("\n");
          setState(() {});
        }
        if (_scrollController.position.pixels !=
                _scrollController.position.maxScrollExtent &&
            scrolling) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    BContext = context;
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.delete),
                tooltip: i18n.Format("log.game.clear"),
                onPressed: () {
                  log_ = "";
                },
              ),
              IconButton(
                icon: Icon(Icons.folder),
                tooltip: '日誌資料夾',
                onPressed: () {
                  utility.OpenFileManager(
                      Directory(join(InstanceDir.absolute.path, "logs")));
                },
              ),
              IconButton(
                icon: Icon(Icons.folder),
                tooltip: '崩潰報告資料夾',
                onPressed: () {
                  utility.OpenFileManager(Directory(
                      join(InstanceDir.absolute.path, "crash-reports")));
                },
              ),
              Tooltip(
                message: i18n.Format("log.game.record"),
                child: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      ShowLog = value!;
                      Config.Change("show_log", value);
                    });
                  },
                  value: ShowLog,
                ),
              ),
              Tooltip(
                message: "記錄檔自動滾動",
                child: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      scrolling = value!;
                    });
                  },
                  value: scrolling,
                ),
              ),
              Text(i18n.Format("log.game.log.title")),
            ],
          ),
          leading: IconButton(
              icon: Icon(Icons.close_outlined),
              tooltip: i18n.Format("log.game.kill"),
              onPressed: () {
                try {
                  LogTimer.cancel();
                  if (process != null) {
                    process.kill();
                  }
                } catch (err) {}
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => new LauncherHome()),
                );
              }),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                  controller: _scrollController, child: Text(log_)),
            ),
          ],
        ));
  }
}

class LogScreen extends StatefulWidget {
  late var instance_folder;

  LogScreen(instance_folder_) {
    instance_folder = instance_folder_;
  }

  @override
  LogScreen_ createState() => LogScreen_(instance_folder);
}
