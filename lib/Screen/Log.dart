import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';

import '../main.dart';
import '../parser.dart';
import '../path.dart';

class LogScreen_ extends State<LogScreen> {
  late var InstanceDirName;

  LogScreen_(instance_folder_) {
    InstanceDirName = instance_folder_;
  }

  var log_ = "";
  var LogTimer;
  late Directory ConfigFolder;
  late File ConfigFile;
  late File AccountFile;
  late Map Account;
  late var cfg_file;
  late Directory InstanceDir;
  late ScrollController _scrollController;
  late var config;
  var process;

  List<void Function(String)> onData = [
    (data) {
      stdout.write(data);
    }
  ];

  void initState() {
    ConfigFolder = configHome;
    AccountFile = File(join(ConfigFolder.absolute.path, "accounts.json"));
    Account = json.decode(AccountFile.readAsStringSync());
    Directory DataHome = dataHome;
    InstanceDir =
        Directory(join(DataHome.absolute.path, "instances", InstanceDirName));
    cfg_file = CFG(File(join(InstanceDir.absolute.path, "instance.cfg"))
            .readAsStringSync())
        .GetParsed();
    var args = jsonDecode(
        File(join(InstanceDir.path, "args.json")).readAsStringSync());
    ConfigFile = File(join(ConfigFolder.absolute.path, "config.json"));
    config = json.decode(ConfigFile.readAsStringSync());
    var VersionID = cfg_file["version"];
    var PlayerName = Account["mojang"][0]["availableProfiles"][0]["name"];
    var ClientJar =
        join(DataHome.absolute.path, "versions", VersionID, "client.jar");
    var Natives =
        join(DataHome.absolute.path, "versions", VersionID, "natives");

    var MinRam = 512;
    var MaxRam = 4096;
    var Width = 854;
    var Height = 480;

    var LauncherVersion = "1.0.0_alpha";
    var LibraryDir = Directory(
            join(DataHome.absolute.path, "versions", VersionID, "libraries"))
        .listSync(recursive: true, followLinks: true);
    var LibraryFiles = "${ClientJar};";
    for (var i in LibraryDir) {
      if (i.runtimeType.toString() == "_File") {
        LibraryFiles += "${i.absolute.path};";
      }
    }

    _scrollController = new ScrollController(
      keepScrollOffset: true,
    );
    start(
        args,
        ClientJar,
        MinRam,
        MaxRam,
        Natives,
        LauncherVersion,
        LibraryFiles,
        PlayerName,
        "RPMLauncher_${VersionID}",
        InstanceDir.absolute.path,
        join(DataHome.absolute.path, "assets"),
        VersionID,
        Account["mojang"][0]["availableProfiles"][0]["uuid"],
        Account["mojang"][0]["accessToken"],
        Account.keys.first,
        Width,
        Height);
    super.initState();
    setState(() {});
  }

  start(
      args,
      String ClientJar,
      MinRam,
      MaxRam,
      Natives,
      LauncherVersion,
      ClassPath,
      PlayerName,
      VersionID,
      GameDir,
      AssetsDirRoot,
      AssetIndex,
      UUID,
      Token,
      AuthType,
      Width,
      Height) async {
    var a = {
      r"${auth_player_name}": PlayerName,
      r"${version_name}": VersionID,
      r"${game_directory}": GameDir,
      r"${assets_root}": AssetsDirRoot,
      r"${assets_index_name}": AssetIndex,
      r"${auth_uuid}": UUID,
      r"${auth_access_token}": Token,
      r"${user_type}": AuthType,
      r"${version_type}": "RPMLauncher_${LauncherVersion}",
      r"${natives_directory}": Natives,
      r"${launcher_name}": "RPMLauncher",
      r"${launcher_version}": LauncherVersion,
      r"${classpath}": ClassPath
    };
    List<String> args_ = [
      "-Dminecraft.client.jar=${ClientJar}", //Client Jar
      "-Xmn${MinRam}m", //最小記憶體
      "-Xmx${MaxRam}m", //最大記憶體
    ];
    for (var jvm_i in args["jvm"]) {
      if (jvm_i.runtimeType == Map) {
        for (var rules_i in jvm_i["rules"]) {
          if (rules_i["os"]["name"] == Platform.operatingSystem) {
            args_ = args + jvm_i["value"];
          }
          if (rules_i["os"].containsKey("version")) {
            if (rules_i["os"]["version"] == Platform.operatingSystemVersion) {
              args_ = args + jvm_i["value"];
            }
          }
        }
      } else {
        if (jvm_i.runtimeType == String && jvm_i.startsWith("-D")) {
          for (var i in a.keys) {
            if (jvm_i.contains(i)) {
              args_.add(jvm_i.replaceAll(i, a[i]));
            }
          }
        } else if (a.containsKey(jvm_i)) {
          args_.add(a[jvm_i] ?? "");
        } else if (jvm_i.runtimeType == String) {
          args_.add(jvm_i);
        }
      }
    }
    args_.add("net.minecraft.client.main.Main"); //程式進入點
    for (var game_i in args["game"]) {
      if (game_i.runtimeType == String && game_i.startsWith("--")) {
        args_.add(game_i);
      } else if (a.containsKey(game_i)) {
        args_.add(a[game_i] ?? "");
      }
    }
    this.process = await Process.start("\"${config["java_path"]}\"", args_,
        workingDirectory: GameDir);
    this.process.stdout.transform(utf8.decoder).listen((data) {
      //error
      this.onData.forEach((event) {
        log_ = log_ + data;
      });
    });
    this.process.stderr.transform(utf8.decoder).listen((data) {
      //log
      this.onData.forEach((event) {
        log_ = log_ + data;
      });
    });
    this.process.exitCode.then((code) {
      print(code);
      process = null;
    });
    const oneSec = const Duration(seconds: 1);
    LogTimer = new Timer.periodic(
        oneSec,
        (Timer t) => setState(() {
              if (log_.split("\n").length > 120) { //delete log
                var LogList = log_.split("\n");
                LogList.removeAt(0);
                log_ = LogList.join("\n");
              }
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                curve: Curves.easeOut,
                duration: const Duration(milliseconds: 300),
              );
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
                  utility()
                      .OpenFileManager(join(dataHome.absolute.path, "logs"));
                },
              ),
              IconButton(
                icon: Icon(Icons.folder),
                tooltip: '崩潰報告資料夾',
                onPressed: () {
                  utility().OpenFileManager(
                      join(dataHome.absolute.path, "crash-reports"));
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
                  MaterialPageRoute(builder: (context) => new MyApp()),
                );
              }),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: SingleChildScrollView(
                    controller: _scrollController, child: Text(log_))),
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
