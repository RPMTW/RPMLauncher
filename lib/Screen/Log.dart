import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dart_big5/big5.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:io/io.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Launcher/Arguments.dart';
import 'package:rpmlauncher/Launcher/Forge/ArgsHandler.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Game/Account.dart';
import 'package:rpmlauncher/Model/Game/GameLogs.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Utility/Process.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Widget/Dialog/GameCrash.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../Utility/LauncherInfo.dart';
import '../main.dart';

class _LogScreenState extends State<LogScreen> {
  GameLogs _logs = GameLogs.empty();
  GameLogs logs = GameLogs.empty();
  String errorLog_ = "";

  bool searching = false;
  TextEditingController _searchController = TextEditingController();
  bool scrolling = true;

  final int macLogLength = Config.getValue("max_log_length");

  Process? process;
  late Timer logTimer;
  late InstanceConfig instanceConfig;
  late Directory instanceDir;
  late ScrollController _scrollController;
  late bool showLog;
  late Directory nativesTempDir;

  @override
  void initState() {
    instanceDir = InstanceRepository.getInstanceDir(widget.instanceUUID);
    instanceConfig = InstanceRepository.instanceConfig(widget.instanceUUID);
    String gameVersionID = instanceConfig.version;
    ModLoaders loader = ModLoaderUttily.getByString(instanceConfig.loader);
    Map args = json.decode(GameRepository.getArgsFile(gameVersionID, loader,
            loaderVersion: instanceConfig.loaderVersion)
        .readAsStringSync());

    Account account = Account.getByIndex(Account.getIndex());

    File clientFile = GameRepository.getClientJar(gameVersionID);

    int minRam = 512;
    int maxRam =
        (instanceConfig.javaMaxRam ?? Config.getValue("java_max_ram") as double)
            .toInt();

    int width = Config.getValue("game_width");
    int height = Config.getValue("game_height");

    String libraryFiles =
        instanceConfig.libraries.getLibrariesLauncherArgs(clientFile);

    showLog = Config.getValue("show_log");

    File optionsFile = File(join(instanceDir.path, 'options.txt'));
    if (optionsFile.existsSync()) {
      Map minecraftOptions =
          Uttily.parseJarManifest(optionsFile.readAsStringSync());
      minecraftOptions['lang'] = Config.getValue("lang_code");
      String result = "";
      for (var i in minecraftOptions.keys) {
        result = result + (i + ":" + minecraftOptions[i] + "\n");
      }
      optionsFile.writeAsStringSync(result);
    } else {
      optionsFile.writeAsStringSync("lang:${Config.getValue("lang_code")}");
    }

    nativesTempDir = GameRepository.getNativesTempDir();
    copyPathSync(
        GameRepository.getNativesDir(gameVersionID).path, nativesTempDir.path);

    _scrollController = ScrollController(
      keepScrollOffset: true,
    );

    Map variable = {
      r"${auth_player_name}": account.username,
      r"${version_name}": "RPMLauncher",
      r"${game_directory}": instanceDir.absolute.path,
      r"${assets_root}": GameRepository.getAssetsDir().path,
      r"${assets_index_name}": gameVersionID,
      r"${auth_uuid}": account.uuid,
      r"${auth_access_token}": account.accessToken,
      r"${user_type}": account.type.name,
      r"${version_type}": "RPMLauncher_${LauncherInfo.getFullVersion()}",
      r"${natives_directory}": nativesTempDir.absolute.path,
      r"${launcher_name}": "RPMLauncher",
      r"${launcher_version}": LauncherInfo.getFullVersion()
    };
    List<String> args_ = [
      "-Dminecraft.client.jar=${clientFile.path}", //Client Jar
      "-Xmn${minRam}m", //最小記憶體
      "-Xmx${maxRam}m", //最大記憶體
      "-cp", // classpath
      libraryFiles,
    ];

    args_.addAll(
        (instanceConfig.javaJvmArgs ?? Config.getValue('java_jvm_args'))
            .toList()
            .cast<String>());

    List<String> gameArgs = [
      "--width",
      width.toString(),
      "--height",
      height.toString(),
    ];

    if (loader == ModLoaders.fabric || loader == ModLoaders.vanilla) {
      args_ = Arguments().argumentsDynamic(
          args, variable, args_, instanceConfig.comparableVersion);
    } else if (loader == ModLoaders.forge) {
      args_ = ForgeArgsHandler().get(args, variable, args_);
    }
    args_.addAll(gameArgs);

    super.initState();
    start(args_, gameVersionID);
  }

  Future<void> start(List<String> args, String gameVersionID) async {
    List<String> _args = [];
    int javaVersion = instanceConfig.javaVersion;
    String javaPath = instanceConfig.toMap()["java_path_$javaVersion"] ??
        Config.getValue("java_path_$javaVersion");
    await chmod(javaPath);

    String exec = javaPath;

    String? wrapperCommand = Config.getValue('wrapper_command');

    if (wrapperCommand != null) {
      List<String> _ = wrapperCommand.split(' ');

      if (_.isNotEmpty) {
        exec = _[0];

        _.forEach((element) {
          if (_.indexOf(element) != 0) {
            _args.add(element);
          }
        });
      }
    }

    _args.addAll(args);

    process = await Process.start(exec, _args,
        workingDirectory: instanceDir.absolute.path,
        environment: {'APPDATA': dataHome.absolute.path});

    setState(() {});
    process?.stdout.listen((data) {
      String string = Big5TransformDecode(data);
      logs.addLog(string);
      if (showLog && !searching) {
        _logs = logs;
        setState(() {});
      } else if (searching) {
        _logs = logs
            .whereLog(
                (log) => log.formattedString.contains(_searchController.text))
            .toList();
        setState(() {});
      }
    });
    process?.stderr.transform(utf8.decoder).listen((data) {
      //error
      Uttily.onData.forEach((event) {
        errorLog_ += data;
      });
    });
    process?.exitCode.then((code) {
      if (nativesTempDir.existsSync()) {
        nativesTempDir.deleteSync(recursive: true);
      }

      process = null;
      instanceConfig.lastPlay = DateTime.now().millisecondsSinceEpoch;

      /// 143 代表手動強制關閉
      bool exitSuccessful = (code == 0 || code == 143) &&
          // 1.17離開遊戲的時候會有退出代碼 -1
          !(code == -1 &&
              instanceConfig.comparableVersion >= Version(1, 17, 0));
      logTimer.cancel();
      if (exitSuccessful) {
        bool autoCloseLogScreen = Config.getValue("auto_close_log_screen");

        if (autoCloseLogScreen) {
          if (widget.newWindow) {
            exit(0);
          } else {
            navigator.pushNamed('home');
          }
        }
      } else {
        showDialog(
          context: navigator.context,
          builder: (context) => GameCrash(
            errorCode: code.toString(),
            errorLog: errorLog_,
            newWindow: widget.newWindow,
          ),
        );
      }
    });

    const oneSec = Duration(seconds: 1);
    logTimer = Timer.periodic(oneSec, (timer) {
      instanceConfig.playTime =
          instanceConfig.playTime + Duration(seconds: 1).inMilliseconds;

      if (showLog && !searching) {
        if (logs.length > macLogLength) {
          //delete log
          logs =
              logs.getRange(logs.length - macLogLength, logs.length).toList();
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
        _logs = logs;
        setState(() {});
      } else if (searching) {
        _logs = logs
            .whereLog(
                (log) => log.formattedString.contains(_searchController.text))
            .toList();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    try {
      logTimer.cancel();
      _logs.clear();
      logs.clear();
      _searchController.dispose();
      _scrollController.dispose();
    } catch (e) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leadingWidth: 550,
          title: Text(I18n.format("log.game.log.title")),
          leading: Row(
            children: [
              IconButton(
                  icon: Icon(Icons.close_outlined),
                  tooltip: I18n.format("log.game.kill"),
                  onPressed: () {
                    try {
                      logTimer.cancel();
                      process?.kill();
                      if (nativesTempDir.existsSync()) {
                        nativesTempDir.deleteSync(recursive: true);
                      }
                    } catch (err) {}
                    if (widget.newWindow) {
                      exit(0);
                    } else {
                      navigator.push(
                          PushTransitions(builder: (context) => HomePage()));
                    }
                  }),
              IconButton(
                icon: Icon(Icons.delete),
                tooltip: I18n.format("log.game.clear"),
                onPressed: () {
                  logs.clear();
                  setState(() {});
                },
              ),
              IconButton(
                icon: Icon(Icons.folder),
                tooltip: I18n.format('log.folder.main'),
                onPressed: () {
                  Uttily.openFileManager(
                      Directory(join(instanceDir.absolute.path, "logs")));
                },
              ),
              IconButton(
                icon: Icon(Icons.folder),
                tooltip: I18n.format('log.folder.crash'),
                onPressed: () {
                  Uttily.openFileManager(Directory(
                      join(instanceDir.absolute.path, "crash-reports")));
                },
              ),
              Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    showLog = value!;
                    Config.change("show_log", value);
                  });
                },
                value: showLog,
              ),
              I18nText("log.game.record"),
              Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    scrolling = value!;
                  });
                },
                value: scrolling,
              ),
              I18nText("log.game.scrolling"),
            ],
          ),
          actions: [
            Container(
                alignment: Alignment.center,
                width: 250,
                height: 250,
                child: TextField(
                  textAlign: TextAlign.center,
                  controller: _searchController,
                  onChanged: (value) {
                    _logs = logs
                        .whereLog((log) => log.source
                            .toLowerCase()
                            .contains(value.toLowerCase()))
                        .toList();
                    searching = value.isNotEmpty;
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: I18n.format("log.game.search"),
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
        body: Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              if (pointerSignal.scrollDelta.dy < -10 ||
                  pointerSignal.scrollDelta.dy > 10) {
                scrolling = false;
              } else {
                scrolling = true;
              }
              setState(() {});
            }
          },
          child: ListView.builder(
              controller: _scrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                GameLog log = _logs[index];
                // TODO: [SelectableText] 讓遊戲日誌上的文字變為可選文字
                return ListTile(
                  minLeadingWidth: 320,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 120,
                        child: AutoSizeText(
                          log.thread,
                          style: TextStyle(color: Colors.lightBlue.shade300),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: AutoSizeText(
                          DateFormat.jms(Platform.localeName).format(log.time),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: log.type.getText(),
                      ),
                    ],
                  ),
                  title: SelectableText(
                    log.formattedString,
                    style: TextStyle(fontFamily: 'mono', fontSize: 15),
                  ),
                );
              }),
        ));
  }
}

class LogScreen extends StatefulWidget {
  final String instanceUUID;
  final bool newWindow;

  const LogScreen({required this.instanceUUID, this.newWindow = false});

  @override
  _LogScreenState createState() => _LogScreenState();
}
