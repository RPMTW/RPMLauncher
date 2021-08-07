import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:RPMLauncher/Account/Account.dart';
import 'package:RPMLauncher/MCLauncher/Arguments.dart';
import 'package:RPMLauncher/MCLauncher/Fabric/FabricAPI.dart';
import 'package:RPMLauncher/MCLauncher/Forge/ArgsHandler.dart';
import 'package:RPMLauncher/MCLauncher/Forge/ForgeAPI.dart';
import 'package:RPMLauncher/MCLauncher/GameRepository.dart';
import 'package:RPMLauncher/MCLauncher/InstanceRepository.dart';
import 'package:RPMLauncher/Utility/Config.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/utility.dart';
import 'package:RPMLauncher/Widget/GameCrash.dart';
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
  var scrolled = false;
  var process;
  var scrolling = false;
  late var BContext;

  List<void Function(String)> onData = [
    (data) {
      stdout.write(data);
    }
  ];

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
        account.GetByIndex(account.GetType(), account.GetIndex())["UserName"];
    var ClientJar = GameRepository.getClientJar(VersionID).absolute.path;
    var Natives = GameRepository.getNativesDir(VersionID).absolute.path;

    var MinRam = 512;
    var MaxRam = Config().GetValue("java_max_ram");
    var Width = Config().GetValue("game_width");
    var Height = Config().GetValue("game_height");

    late var LibraryFiles;
    var LibraryDir = GameRepository.getVanillaLibraryDir(VersionID)
        .listSync(recursive: true, followLinks: true);
    LibraryFiles = ClientJar + utility.GetSeparator();
    for (var i in LibraryDir) {
      if (i.runtimeType.toString() == "_File") {
        LibraryFiles += "${i.absolute.path}${utility.GetSeparator()}";
      }
    }

    if (Loader == ModLoader().Fabric) {
      LibraryFiles += FabricAPI().GetLibraryFiles(VersionID, ClientJar);
    } else if (Loader == ModLoader().Forge) {
      LibraryFiles += ForgeAPI().GetLibraryFiles(VersionID, ClientJar);
    }

    _scrollController = new ScrollController(
      keepScrollOffset: true,
    );
    _scrollController.addListener(() {
      if (scrolling != true) {
        scrolled = true;
      }
    });
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
        account.GetByIndex(account.GetType(), account.GetIndex())["UUID"],
        account.GetByIndex(
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
    this.process = await Process.start(
        "${config["java_path_${InstanceConfig["java_version"]}"]}", //Java Path
        args_,
        workingDirectory: GameDir,
        environment: {'APPDATA': dataHome.absolute.path});
    this.process.stdout.transform(utf8.decoder).listen((data) {
      this.onData.forEach((event) {
        //log
        log_ += data;
      });
    });
    this.process.stderr.transform(utf8.decoder).listen((data) {
      //error
      this.onData.forEach((event) {
        errorLog_ += data;
      });
    });
    this.process.exitCode.then((code) {
      process = null;
      if (code != 0) {
        showDialog(
          context: BContext,
          builder: (BContext) => GameCrash(code.toString(), errorLog_),
        );
      }
    });
    const oneSec = const Duration(seconds: 1);
    LogTimer = new Timer.periodic(
        oneSec,
        (Timer t) => setState(() {
              if (log_.split("\n").length >
                  Config().GetValue("max_log_length")) {
                //delete log
                var LogList = log_.split("\n");
                LogList.removeAt(0);
                log_ = LogList.join("\n");
              }
              if (scrolled == false) {
                scrolling = true;
                _scrollController
                    .animateTo(
                      _scrollController.position.maxScrollExtent,
                      curve: Curves.easeOut,
                      duration: const Duration(milliseconds: 300),
                    )
                    .then((value) => scrolling = false);
              }
              if (_scrollController.position.pixels ==
                  _scrollController.position.maxScrollExtent) {
                scrolled = false;
              }
            }));
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
                tooltip: '清除遊戲日誌',
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
              Text("啟動器日誌"),
            ],
          ),
          leading: IconButton(
              icon: Icon(Icons.close_outlined),
              tooltip: '強制關閉遊戲',
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
