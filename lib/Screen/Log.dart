import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/MCLauncher/Arguments.dart';
import 'package:rpmlauncher/MCLauncher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/MCLauncher/Forge/ArgsHandler.dart';
import 'package:rpmlauncher/MCLauncher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../LauncherInfo.dart';
import '../main.dart';
import '../path.dart';

class LogScreen_ extends State<LogScreen> {
  late var InstanceDirName;

  LogScreen_(instance_folder_) {
    InstanceDirName = instance_folder_;
  }

  var log_ = "";
  var errorLog_ = "";
  var LogTimer;
  late Directory ConfigFolder;
  late File ConfigFile;
  late File AccountFile;
  late var InstanceConfig;
  late Directory InstanceDir;
  late ScrollController _scrollController;
  late var config;
  var scrolled = false;
  var process;
  var scrolling = false;
  List<void Function(String)> onData = [
    (data) {
      stdout.write(data);
    }
  ];

  void initState() {
    ConfigFolder = configHome;
    Directory DataHome = dataHome;
    InstanceDir =
        Directory(join(DataHome.absolute.path, "instances", InstanceDirName));
    InstanceConfig = json.decode(
        File(join(InstanceDir.absolute.path, "instance.json"))
            .readAsStringSync());
    ConfigFile = File(join(ConfigFolder.absolute.path, "config.json"));
    config = json.decode(ConfigFile.readAsStringSync());
    var VersionID = InstanceConfig["version"];
    var Loader = InstanceConfig["loader"];
    var args;
    if (Loader == ModLoader().Fabric || Loader == ModLoader().Forge) {
      args = jsonDecode(File(join(DataHome.absolute.path, "versions", VersionID,
              "${Loader}_args.json"))
          .readAsStringSync());
    } else {
      args = jsonDecode(
          File(join(DataHome.absolute.path, "versions", VersionID, "args.json"))
              .readAsStringSync());
    }

    var PlayerName =
        account.GetByIndex(account.GetType(), account.GetIndex())["UserName"];
    var ClientJar =
        join(DataHome.absolute.path, "versions", VersionID, "client.jar");
    var Natives =
        join(DataHome.absolute.path, "versions", VersionID, "natives");

    var MinRam = 512;
    var MaxRam = Config().GetValue("java_max_ram");
    var Width = Config().GetValue("game_width");
    var Height = Config().GetValue("game_height");

    late var LibraryFiles;
    var LibraryDir = Directory(join(DataHome.absolute.path, "versions",
            VersionID, "libraries", ModLoader().None))
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
      args_ = ForgeArgsHandler().Get(args, Variable, args_);

      print(args_);
      // var ForgeLibraryDir = Directory(join(dataHome.absolute.path, "versions",
      //         GameVersionID, "libraries", ModLoader().Forge))
      //     .listSync(recursive: true, followLinks: true);
      // var ForgeLibraryFiles = "";
      // for (var i in ForgeLibraryDir) {
      //   if (i.runtimeType.toString() == "_File") {
      //     ForgeLibraryFiles += "${i.absolute.path},";
      //   }
      // }
      // args_.add("-DignoreList=${ClientJar},${ForgeLibraryFiles}");
      // args_.add(
      //     "-DmergeModules=jna-5.8.0.jar,jna-platform-58.0.jar,java-objc-bridge-1.0.0.jar");
      // args_.add(
      //     "-DlibraryDirectory=${join(dataHome.absolute.path, "versions", GameVersionID, "libraries")}");
      // args_.add("-p");
      // args_.add("${ForgeLibraryFiles.replaceAll(",", ";")}");
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
        print(data);
      });
    });
    this.process.exitCode.then((code) {
      process = null;
    });
    const oneSec = const Duration(seconds: 1);
    LogTimer = new Timer.periodic(
        oneSec,
        (Timer t) => setState(() {
              if (log_.split("\n").length > 120) {
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
