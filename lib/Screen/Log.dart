// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Launcher/Arguments.dart';
import 'package:rpmlauncher/Launcher/Forge/ArgsHandler.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/GameCrash.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../LauncherInfo.dart';
import '../main.dart';

class LogScreen_ extends State<LogScreen> {
  String _logs = "";
  List<String> logs = [];
  String errorLog_ = "";
  var LogTimer;
  late File ConfigFile;
  late File AccountFile;
  late InstanceConfig instanceConfig;
  late Directory InstanceDir;
  late ScrollController _scrollController;
  var process;
  final int MaxLogLength = Config.getValue("max_log_length");
  late bool ShowLog;
  bool Searching = false;
  TextEditingController SearchController = TextEditingController();
  bool scrolling = true;

  void initState() {
    Directory DataHome = dataHome;
    InstanceDir = InstanceRepository.getInstanceDir(widget.InstanceDirName);
    instanceConfig = InstanceRepository.instanceConfig(widget.InstanceDirName);
    String VersionID = instanceConfig.version;
    ModLoaders Loader = ModLoaderUttily.getByString(instanceConfig.loader);
    var args = json.decode(GameRepository.getArgsFile(
            VersionID, Loader, instanceConfig.loaderVersion)
        .readAsStringSync());

    String PlayerName = account.getByIndex(account.getIndex())["UserName"];
    String ClientJar = GameRepository.getClientJar(VersionID).absolute.path;
    String Natives = GameRepository.getNativesDir(VersionID).absolute.path;

    int MinRam = 512;
    int MaxRam = instanceConfig.javaMaxRam ?? Config.getValue("java_max_ram");
    var Width = Config.getValue("game_width");
    var Height = Config.getValue("game_height");

    late var LibraryFiles;
    var LibraryDir = GameRepository.getLibraryRootDir(VersionID)
        .listSync(recursive: true, followLinks: true);
    LibraryFiles = ClientJar + utility.getSeparator();
    for (var i in LibraryDir) {
      if (i.runtimeType.toString() == "_File") {
        LibraryFiles += "${i.absolute.path}${utility.getSeparator()}";
      }
    }

    ShowLog = Config.getValue("show_log");

    File optionsFile = File(join(InstanceDir.path, 'options.txt'));
    if (optionsFile.existsSync()) {
      Map MCOptions = utility.parseJarManifest(optionsFile.readAsStringSync());
      MCOptions['lang'] = Config.getValue("lang_code");
      String result = "";
      for (var i in MCOptions.keys) {
        result = result + (i + ":" + MCOptions[i] + "\n");
      }
      optionsFile.writeAsStringSync(result);
    } else {
      optionsFile.writeAsStringSync("lang:${Config.getValue("lang_code")}");
    }

    _scrollController = ScrollController(
      keepScrollOffset: true,
    );
    start(
        args,
        Loader,
        ClientJar,
        MinRam,
        MaxRam,
        Natives,
        LauncherInfo.getVersion(),
        LibraryFiles,
        PlayerName,
        "RPMLauncher_$VersionID",
        InstanceDir.absolute.path,
        join(DataHome.absolute.path, "assets"),
        VersionID,
        account.getByIndex(account.getIndex())["UUID"],
        account.getByIndex(account.getIndex())["AccessToken"],
        account.getByIndex(account.getIndex())['Type'],
        Width,
        Height);
    super.initState();
    setState(() {});
  }

  start(
      args,
      ModLoaders Loader,
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
    Map Variable = {
      r"${auth_player_name}": PlayerName,
      r"${version_name}": LauncherVersionID,
      r"${game_directory}": GameDir,
      r"${assets_root}": AssetsDirRoot,
      r"${assets_index_name}": GameVersionID,
      r"${auth_uuid}": UUID,
      r"${auth_access_token}": Token,
      r"${user_type}": AuthType,
      r"${version_type}": "RPMLauncher_$LauncherVersion",
      r"${natives_directory}": Natives,
      r"${launcher_name}": "RPMLauncher",
      r"${launcher_version}": LauncherVersion
    };
    List<String> args_ = [
      "-Dminecraft.client.jar=$ClientJar", //Client Jar
      "-Xmn${MinRam}m", //最小記憶體
      "-Xmx${MaxRam}m", //最大記憶體
      "-cp",
      ClassPath,
    ];
    args_.addAll((instanceConfig.javaMaxRam ?? Config.getValue('java_jvm_args'))
        .toList()
        .cast<String>());

    List<String> GameArgs = [
      "--width",
      Width.toString(),
      "--height",
      Height.toString(),
    ];

    if (Loader == ModLoaders.Fabric || Loader == ModLoaders.Vanilla) {
      args_ =
          Arguments().ArgumentsDynamic(args, Variable, args_, GameVersionID);
    } else if (Loader == ModLoaders.Forge) {
      args_ = ForgeArgsHandler().get(args, Variable, args_);
    }
    args_.addAll(GameArgs);
    int JavaVersion = instanceConfig.javaVersion;

    this.process = await Process.start(
        instanceConfig.rawData["java_path_$JavaVersion"] ??
            Config.getValue("java_path_$JavaVersion"), //Java Path
        args_,
        workingDirectory: GameDir,
        environment: {'APPDATA': dataHome.absolute.path});

    setState(() {});
    this.process.stdout.transform(utf8.decoder).listen((data) {
      utility.onData.forEach((event) {
        logs.add(data);
        if (ShowLog && !Searching) {
          _logs = logs.join("");
          setState(() {});
        } else if (Searching) {
          _logs = logs
              .where((log) => log.contains(SearchController.text))
              .toList()
              .join("");
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
      instanceConfig.lastPlay = DateTime.now().millisecondsSinceEpoch;
      if (code != 0) {
        //1.17離開遊戲的時候會有退出代碼 -1
        if (code == -1 && Arguments().ParseGameVersion(GameVersionID) >= 17)
          return;
        showDialog(
          context: navigator.context,
          builder: (BContext) => GameCrash(
            ErrorCode: code.toString(),
            ErrorLog: errorLog_,
          ),
        );
      }
    });
    const oneSec = const Duration(seconds: 1);
    LogTimer = Timer.periodic(oneSec, (timer) {
      instanceConfig.playTime =
          instanceConfig.playTime + Duration(seconds: 1).inMilliseconds;
      if (ShowLog && !Searching) {
        if (logs.length > MaxLogLength) {
          //delete log
          logs =
              logs.getRange(logs.length - MaxLogLength, logs.length).toList();
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
        _logs = logs.join("");
        setState(() {});
      } else if (Searching) {
        _logs = logs
            .where((log) => log.contains(SearchController.text))
            .toList()
            .join("");
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leadingWidth: 300,
          title: Text(i18n.format("log.game.log.title")),
          leading: Row(
            children: [
              IconButton(
                  icon: Icon(Icons.close_outlined),
                  tooltip: i18n.format("log.game.kill"),
                  onPressed: () {
                    try {
                      LogTimer.cancel();
                      if (process != null) {
                        process.kill();
                      }
                    } catch (err) {}
                    if (widget.NewWindow) {
                      exit(0);
                    } else {
                      navigator.push(
                          PushTransitions(builder: (context) => HomePage()));
                    }
                  }),
              IconButton(
                icon: Icon(Icons.delete),
                tooltip: i18n.format("log.game.clear"),
                onPressed: () {
                  logs.clear();
                  setState(() {});
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
                message: i18n.format("log.game.record"),
                child: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      ShowLog = value!;
                      Config.change("show_log", value);
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
            ],
          ),
          actions: [
            Container(
                alignment: Alignment.center,
                width: 250,
                height: 250,
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: SearchController,
                  onChanged: (String value) {
                    _logs = logs
                        .where((log) => log.contains(value))
                        .toList()
                        .join("");
                    Searching = value.isNotEmpty;
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: "搜尋遊戲日誌",
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white12, width: 3.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlue, width: 3.0),
                    ),
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ))
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                  controller: _scrollController, child: SelectableText(_logs)),
            ),
          ],
        ));
  }
}

class LogScreen extends StatefulWidget {
  final String InstanceDirName;
  final bool NewWindow;

  LogScreen({required this.InstanceDirName, this.NewWindow = false}) {}

  @override
  LogScreen_ createState() => LogScreen_();
}
