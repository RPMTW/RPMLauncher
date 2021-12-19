import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_big5/big5.dart';
import 'package:flutter/gestures.dart';
import 'package:io/io.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Launcher/Arguments.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeInstallProfile.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Account/Account.dart';
import 'package:rpmlauncher/Model/Game/GameLogs.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Model/IO/Properties.dart';
import 'package:rpmlauncher/Route/PushTransitions.dart';
import 'package:rpmlauncher/Screen/HomePage.dart';
import 'package:rpmlauncher/Utility/Process.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Utility/Data.dart';

import 'package:rpmlauncher/Widget/Dialog/GameCrash.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:window_size/window_size.dart';

import '../Utility/LauncherInfo.dart';

class _LogScreenState extends State<LogScreen> {
  GameLogs _logs = GameLogs.empty();
  GameLogs logs = GameLogs.empty();
  String errorLog_ = "";

  bool searching = false;
  late TextEditingController _searchController;
  late TextEditingController _serverCommandController;
  bool scrolling = true;

  final int macLogLength = Config.getValue("max_log_length");

  Process? process;
  late Timer logTimer;
  late InstanceConfig instanceConfig;
  late Directory instanceDir;
  late ScrollController _scrollController;
  late bool showLog;
  late MinecraftSide side;
  Directory? nativesTempDir;

  void killGame() {
    if (side.isServer) {
      process?.stdin.writeln("/stop");
    }
    process?.kill();
  }

  @override
  void initState() {
    _scrollController = ScrollController(
      keepScrollOffset: true,
    );
    _searchController = TextEditingController();
    _serverCommandController = TextEditingController();

    super.initState();

    instanceDir = InstanceRepository.getInstanceDir(widget.instanceUUID);
    instanceConfig = InstanceRepository.instanceConfig(widget.instanceUUID);

    setWindowTitle("RPMLauncher - ${instanceConfig.name}");

    String gameVersionID = instanceConfig.version;
    side = instanceConfig.sideEnum;
    ModLoader loader = ModLoaderUttily.getByString(instanceConfig.loader);
    String? loaderVersion = instanceConfig.loaderVersion;
    File argsFile = GameRepository.getArgsFile(gameVersionID, loader, side,
        loaderVersion: loaderVersion);

    if (loader == ModLoader.forge && !argsFile.existsSync()) {
      File forgeProfileFile = GameRepository.getForgeProfileFile(gameVersionID);
      if (forgeProfileFile.existsSync()) {
        try {
          ForgeInstallProfile profile = ForgeInstallProfile.fromNewJson(
              json.decode(forgeProfileFile.readAsStringSync()));
          ForgeAPI.handlingArgs(
              profile.versionJson, gameVersionID, loaderVersion!);
        } catch (e) {}
      }
    }

    Map argsMeta = json.decode(argsFile.readAsStringSync());

    Version comparableVersion = instanceConfig.comparableVersion;

    Account account = AccountStorage().getDefault()!;

    File clientFile = GameRepository.getClientJar(gameVersionID);

    int minRam = 512;
    int maxRam =
        (instanceConfig.javaMaxRam ?? Config.getValue("java_max_ram") as double)
            .toInt();

    int width = Config.getValue("game_width");
    int height = Config.getValue("game_height");

    String libraryFiles = instanceConfig.libraries
        .getLibrariesLauncherArgs(side.isClient ? clientFile : null);

    showLog = Config.getValue("show_log");

    List<String> args_ = [
      ...(side.isClient
          ? ["-Dminecraft.client.jar=${clientFile.path}"]
          : []), //Client Jar
      "-Xmn${minRam}m", //最小記憶體
      "-Xmx${maxRam}m", //最大記憶體
    ];

    args_.addAll(
        (instanceConfig.javaJvmArgs ?? Config.getValue('java_jvm_args'))
            .toList()
            .cast<String>());

    List<String> gameArgs = [];

    if (side.isClient) {
      if (comparableVersion < Version(1, 13, 0)) {
        args_.addAll(["-cp", libraryFiles]);
      }

      if (argsMeta.containsKey('logging') &&
          argsMeta['logging'].containsKey('client')) {
        Map logging = argsMeta['logging']['client'];
        if (logging.containsKey('file')) {
          Map file = logging['file'];
          String sha1 = file['sha1'];
          File _file = GameRepository.getAssetsObjectFile(sha1);
          if (_file.existsSync()) {
            gameArgs.add(logging['argument']
                .toString()
                .replaceAll(r"${path}", _file.path));
          }
        }
      }

      File optionsFile = File(join(instanceDir.path, 'options.txt'));
      String langCode = Config.getValue("lang_code");

      /// 1.14.4 以下版本沒有 繁體中文 (香港) 的語言選項
      if (comparableVersion <= Version(1, 14, 4) && langCode == "zh_hk") {
        langCode = "zh_tw";
      }

      /// 1.11 以下版本的語言選項格式為 en_US，以上版本為 en_us
      if (comparableVersion < Version(1, 11, 0)) {
        List<String> _ = langCode.split("_");
        if (_.length >= 2) {
          langCode = _[0] + "_" + _[1].toUpperCase();
        }
      }

      if (optionsFile.existsSync()) {
        try {
          Properties properties;
          properties = Properties.decode(
              optionsFile.readAsStringSync(encoding: utf8),
              splitChar: ":");
          properties['lang'] = langCode;
          optionsFile
              .writeAsStringSync(Properties.encode(properties, splitChar: ":"));
        } on FileSystemException {
          /// 若檔案讀取時發生未知錯誤
        }
      } else {
        optionsFile.writeAsStringSync("lang:$langCode");
      }

      nativesTempDir = GameRepository.getNativesTempDir();
      copyPathSync(GameRepository.getNativesDir(gameVersionID).path,
          nativesTempDir!.path);

      if (comparableVersion < Version(1, 13, 0)) {
        args_.add("-Djava.library.path=${nativesTempDir!.absolute.path}");
      }

      Map<String, String> variable = {
        r"${auth_player_name}": account.username,
        r"${version_name}": gameVersionID,
        r"${game_directory}": instanceDir.absolute.path,
        r"${assets_root}": GameRepository.getAssetsDir().path,
        r"${assets_index_name}": instanceConfig.assetsID,
        r"${auth_uuid}": account.uuid,
        r"${auth_access_token}": account.accessToken,
        r"${user_type}":
            "mojang", // 可能是 legacy 或 mojang，但由於RPMLauncher不支援 legacy 帳號登入，所以是 mojang
        r"${version_type}": "RPMLauncher_${LauncherInfo.getFullVersion()}",
        r"${natives_directory}": nativesTempDir!.absolute.path,
        r"${launcher_name}": "RPMLauncher",
        r"${launcher_version}": LauncherInfo.getFullVersion(),
        r"${classpath}": libraryFiles,
        r"${user_properties}": "{}",

        /// Forge Mod Loader
        r"${classpath_separator}": Uttily.getLibrarySeparator(),
        r"${library_directory}": GameRepository.getLibraryGlobalDir().path,
      };

      if (loader == ModLoader.fabric || loader == ModLoader.vanilla) {
        args_.addAll(
            Arguments.getVanilla(argsMeta, variable, comparableVersion));
      } else if (loader == ModLoader.forge) {
        args_.addAll(Arguments.getForge(argsMeta, variable, comparableVersion));
      }
      gameArgs
          .addAll(["--width", width.toString(), "--height", height.toString()]);
    } else if (side.isServer) {
      // args_.add(argsMeta["mainClass"]);
      args_.addAll(["-jar", libraryFiles]);
      args_.add("nogui");
    }

    args_.addAll(gameArgs);

    start(args_, gameVersionID);
  }

  Future<void> start(List<String> args, String gameVersionID) async {
    List<String> _args = [];
    int javaVersion = instanceConfig.javaVersion;
    String javaPath = instanceConfig.storage["java_path_$javaVersion"] ??
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
      late String string;
      if (Platform.isWindows) {
        string = Big5TransformDecode(data);
      } else {
        string = utf8.decode(data);
      }
      if (string.isEmpty) return;
      logs.addLog(string);
      if (showLog && !searching) {
        _logs = logs;
        setState(() {});
      } else if (searching) {
        _logs = logs
            .whereLog((log) =>
                log.formattedString?.contains(_searchController.text) ?? false)
            .toList();
        setState(() {});
      }
    });
    process?.stderr.transform(utf8.decoder).listen((data) {
      //error
      errorLog_ += data;
    });
    process?.exitCode.then((code) {
      try {
        if (nativesTempDir?.existsSync() ?? false) {
          nativesTempDir?.deleteSync(recursive: true);
        }
      } catch (e) {}

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
            errorCode: code,
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

      if (mounted) {
        if (showLog && !searching) {
          if (logs.length > macLogLength) {
            //delete log
            logs =
                logs.getRange(logs.length - macLogLength, logs.length).toList();
          }
          if (_scrollController.hasClients &&
              _scrollController.position.pixels !=
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
              .whereLog((log) =>
                  log.formattedString?.contains(_searchController.text) ??
                  false)
              .toList();
          setState(() {});
        }
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
                      killGame();

                      if (nativesTempDir?.existsSync() ?? false) {
                        nativesTempDir?.deleteSync(recursive: true);
                      }
                    } catch (err) {}
                    if (widget.newWindow) {
                      exit(0);
                    } else {
                      Navigator.of(context).push(
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
        body: Column(
          children: [
            Expanded(
              flex: 15,
              child: Listener(
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
                child:
                    _LogView(scrollController: _scrollController, logs: _logs),
              ),
            ),
            ...side.isServer
                ? [
                    SizedBox(
                      height: 12,
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 50,
                        ),
                        Expanded(
                          child: RPMTextField(
                            hintText: I18n.format("log.server.command"),
                            controller: _serverCommandController,
                            onEditingComplete: () {
                              if (_serverCommandController.text.isNotEmpty) {
                                String command = _serverCommandController.text;

                                if (!command.startsWith("/")) {
                                  //如果指令不包含 /
                                  command = "/" + command;
                                }

                                process?.stdin.writeln(command);

                                _serverCommandController.text = "";
                                scrolling = true;
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 50,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 12,
                    ),
                  ]
                : []
          ],
        ));
  }
}

class _LogView extends StatelessWidget {
  const _LogView({
    Key? key,
    required this.scrollController,
    required this.logs,
  }) : super(key: key);

  final ScrollController scrollController;
  final GameLogs logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isNotEmpty) {
      return ListView.builder(
          controller: scrollController,
          itemCount: logs.length,
          itemBuilder: (context, index) {
            GameLog log = logs[index];
            return log.widget;
          });
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RWLLoading(),
          SizedBox(
            height: 12,
          ),
          I18nText("log.game.log.none",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
              )),
        ],
      );
    }
  }
}

class LogScreen extends StatefulWidget {
  final String instanceUUID;
  final bool newWindow;

  const LogScreen({required this.instanceUUID, this.newWindow = false});

  @override
  _LogScreenState createState() => _LogScreenState();
}
