import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/model/account/Account.dart';
import 'package:rpmlauncher/model/Game/Libraries.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/model/IO/JsonStorage.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/IO/Properties.dart';
import 'package:rpmlauncher/screen/account.dart';
import 'package:rpmlauncher/screen/check_assets.dart';
import 'package:rpmlauncher/screen/ms_oauth_login.dart';
import 'package:rpmlauncher/screen/MojangAccount.dart';
import 'package:rpmlauncher/util/i18n.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/widget/dialog/agree_eula_dialog.dart';
import 'package:rpmlauncher/widget/dialog/CheckDialog.dart';
import 'package:rpmlauncher/widget/rpmtw_design/DynamicImageFile.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';
import 'package:rpmlauncher/widget/rwl_loading.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:uuid/uuid.dart';

class Instance {
  /// 安裝檔的名稱
  String get name => config.name;

  /// UUID of the instance
  final String uuid;

  /// 安裝檔的設定物件
  final InstanceConfig config;

  /// 安裝檔的資料夾
  Directory get directory => InstanceRepository.getInstanceDir(uuid);

  /// 安裝檔的資料夾路徑
  String get path => directory.path;

  File? get imageFile {
    File file = File(join(path, "icon.png"));
    if (file.existsSync()) {
      return file;
    }
    return null;
  }

  Widget imageWidget(
      {double width = 64, double height = 64, bool expand = false}) {
    Widget widget = Image.asset(
      "assets/images/Minecraft.png",
      width: width,
      height: height,
    );

    if (imageFile != null) {
      try {
        widget = DynamicImageFile(
            imageFile: imageFile!, width: width, height: height);
      } catch (e) {}
    } else if (config.loaderEnum == ModLoader.forge) {
      widget = Image.asset(
        "assets/images/Forge.jpg",
        width: width,
        height: height,
      );
    } else if (config.loaderEnum == ModLoader.fabric) {
      widget = Image.asset(
        "assets/images/Fabric.png",
        width: width,
        height: height,
      );
    } else if (config.loaderEnum == ModLoader.unknown) {
      widget = Stack(
        alignment: Alignment.center,
        children: [
          widget,
          const Positioned(
            right: 2,
            top: 2,
            child: Icon(Icons.error_sharp, size: 30, color: Colors.red),
          )
        ],
      );
    }

    if (!expand) {
      widget = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: widget,
      );
    }

    return widget;
  }

  Instance(this.uuid, this.config);

  static Instance? fromUUID(String uuid) {
    InstanceConfig? config = InstanceConfig.fromUUID(uuid);

    if (config != null) {
      return Instance(uuid, config);
    }
    return null;
  }

  Future<void> launch(BuildContext context) async {
    if (!AccountStorage().hasAccount) {
      return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
            title: Text(I18n.format('gui.error.info')),
            content: Text(I18n.format('account.null')),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    AccountScreen.push(context);
                  },
                  child: Text(I18n.format('gui.login')))
            ]),
      );
    } else {
      Account account = AccountStorage().getDefault()!;

      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => FutureBuilder(
              future: Util.validateAccount(account)
                  .timeout(const Duration(seconds: 15), onTimeout: () => false),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  if (!snapshot.data) {
                    //如果帳號已經過期並且嘗試自動更新失敗

                    if (account.type == AccountType.microsoft) {
                      return AlertDialog(
                        title: I18nText.errorInfoText(),
                        content: I18nText("account.refresh.microsoft.error"),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) => MSLoginWidget());
                              },
                              child: I18nText("account.again"))
                        ],
                      );
                    } else {
                      return AlertDialog(
                          title: I18nText.errorInfoText(),
                          content: Text(I18n.format('account.expired')),
                          actions: [
                            ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) => MojangAccount(
                                          accountEmail: account.email ?? ""));
                                },
                                child: Text(I18n.format('account.again')))
                          ]);
                    }
                  } else {
                    //如果帳號未過期
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      navigator.pop();
                      Util.javaCheckDialog(
                          allJavaVersions: config.needJavaVersion,
                          hasJava: () async {
                            if (config.sideEnum.isServer) {
                              File eulaFile = File(join(path, 'eula.txt'));
                              if (!eulaFile.existsSync()) {
                                const Properties properties = Properties({
                                  'eula': 'false',
                                });

                                eulaFile.writeAsStringSync(
                                    Properties.encode(properties));
                              }

                              try {
                                Properties properties;
                                properties = Properties.decode(
                                    eulaFile.readAsStringSync(encoding: utf8));
                                bool agreeEula =
                                    properties['eula'].toString().toBool();

                                if (!agreeEula) {
                                  await showDialog(
                                      context: navigator.context,
                                      builder: (context) => AgreeEulaDialog(
                                          properties: properties,
                                          eulaFile: eulaFile));
                                }
                              } on FileSystemException {}
                            }

                            showDialog(
                                context: navigator.context,
                                builder: (context) => CheckAssetsScreen(
                                      instanceDir: directory,
                                    ));
                          });
                    });

                    return const SizedBox.shrink();
                  }
                } else {
                  return const Center(child: RWLLoading());
                }
              }));
    }
  }

  void openFolder() {
    Util.openFileManager(directory);
  }

  void edit() {
    WindowHandler.create("/instance/${basename(path)}/edit",
        title: "RPMLauncher - $name");
  }

  Future<void> copy() async {
    Future<void> copyInstance() async {
      String uuid = const Uuid().v4();

      await copyPath(path, InstanceRepository.getInstanceDir(uuid).path);

      InstanceConfig newInstanceConfig =
          InstanceRepository.instanceConfig(uuid)!;

      newInstanceConfig.storage['uuid'] = uuid;
      newInstanceConfig.name =
          "${newInstanceConfig.name} (${I18n.format("gui.copy")})";
    }

    showDialog(
        context: navigator.context,
        builder: (context) => FutureBuilder(
            future: copyInstance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return AlertDialog(
                  title: I18nText.tipsInfoText(),
                  content: I18nText('gui.instance.copy.successful'),
                  actions: const [OkClose()],
                );
              } else if (snapshot.hasError) {
                return AlertDialog(
                  title: I18nText.errorInfoText(),
                  content: I18nText('gui.instance.copy.error'),
                  actions: const [OkClose()],
                );
              } else {
                return AlertDialog(
                  title: I18nText.tipsInfoText(),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      I18nText('gui.instance.copy.copying'),
                      const RWLLoading()
                    ],
                  ),
                );
              }
            }));
  }

  Future<void> delete() async {
    showDialog(
      context: navigator.context,
      builder: (context) {
        return CheckDialog(
          title: I18n.format("gui.instance.delete"),
          message: I18n.format('gui.instance.delete.tips'),
          onPressedOK: (context) {
            Navigator.of(context).pop();
            try {
              directory.deleteSync(recursive: true);
            } on FileSystemException {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: I18nText.errorInfoText(),
                        content: I18nText("gui.instance.delete.error"),
                        actions: const [OkClose()],
                      ));
            }
          },
        );
      },
    );
  }

  List<FileSystemEntity> getModFiles() {
    return InstanceRepository.getModRootDir(uuid)
        .listSync()
        .where((file) =>
            extension(file.path, 2).contains('.jar') &&
            file.existsSync() &&
            file is File)
        .toList();
  }
}

/// 安裝檔設定類別
class InstanceConfig {
  late JsonStorage storage;

  /// 安裝檔案名稱
  String get name => storage['name'] ?? "Name not found";

  /// 安裝檔的UUID
  String get uuid => storage['uuid'];

  String get side => storage['side'];

  MinecraftSide get sideEnum => MinecraftSide.values.byName(side);

  /// 安裝檔模組載入器，可以是 forge、fabric、vanilla、unknown
  String get loader => storage['loader'];

  /// 模組載入器的枚舉值 [ModLoader]
  ModLoader get loaderEnum => ModLoaderUttily.getByString(loader);

  /// 安裝檔的遊戲版本
  String get version => storage['version'];

  /// 安裝檔的資源檔案 ID
  String get assetsID => storage['assets_id'];

  /// 可比較大小的遊戲版本
  Version get comparableVersion => Util.parseMCComparableVersion(version);

  /// 安裝檔的模組載入器版本
  String? get loaderVersion => storage['loader_version'];

  /// 安裝檔需要的Java版本，可以是 8/16/17
  int get javaVersion => storage['java_version'];

  List<int> get needJavaVersion {
    List<int> javaVersions = [];
    if (loaderEnum == ModLoader.forge) {
      javaVersions.add(16);
    }
    if (!javaVersions.contains(javaVersion)) {
      javaVersions.add(javaVersion);
    }
    return javaVersions;
  }

  /// 安裝檔的遊玩時間，預設為 0
  int get playTime => storage['play_time'] ?? 0;

  /// 安裝檔最後遊玩的時間，預設為 null
  int? get lastPlay => storage['last_play'];

  String get lastPlayLocalString => lastPlay == null
      ? I18n.format('datas.found.not')
      : Util.formatDate(DateTime.fromMillisecondsSinceEpoch(lastPlay!));

  /// 安裝檔最多可以使用的記憶體，預設為 null
  double? get javaMaxRam => storage['java_max_ram'];

  /// 安裝檔的JVM (Java 虛擬機器) 參數，預設為 null
  List<String>? get javaJvmArgs => storage['java_jvm_args'];

  Libraries get libraries => Libraries.fromList(storage['libraries'] ?? []);

  set name(String value) => storage.setItem('name', value);
  set side(String value) => storage.setItem('side', value);
  set loader(String value) => storage.setItem('loader', value);
  set version(String value) => storage.setItem('version', value);
  set loaderVersion(String? value) => storage.setItem('loader_version', value);
  set javaVersion(int value) => storage.setItem('java_version', value);
  set playTime(int? value) => storage.setItem('play_time', value ?? 0);
  set lastPlay(int? value) => storage.setItem('last_play', value ?? 0);
  set javaMaxRam(double? value) => storage.setItem('java_max_ram', value);
  set javaJvmArgs(List<String>? value) =>
      storage.setItem('java_jvm_args', value);
  set libraries(Libraries value) =>
      storage.setItem('libraries', value.toJson());

  InstanceConfig(
      {required String name,
      required MinecraftSide side,
      required String loader,
      required String version,
      required int javaVersion,
      required String uuid,
      required String assetsID,
      String? loaderVersion,
      int? playTime,
      int? lastPlay,
      double? javaMaxRam,
      List<String>? javaJvmArgs,
      Libraries? libraries}) {
    storage = JsonStorage(InstanceRepository.instanceConfigFile(uuid));

    storage['uuid'] = uuid;

    storage['name'] = name;
    storage['side'] = side.name;
    storage['loader'] = loader;
    storage['version'] = version;
    storage['loader_version'] = loaderVersion;
    storage['java_version'] = javaVersion;
    storage['play_time'] = playTime;
    storage['last_play'] = lastPlay;
    storage['java_max_ram'] = javaMaxRam;
    storage['java_jvm_args'] = javaJvmArgs;
    storage['libraries'] = (libraries ?? Libraries([])).toJson();
    storage['assets_id'] = assetsID;
  }

  factory InstanceConfig.unknown([File? file]) {
    String name = file == null ? "unknown" : basename(file.parent.path);
    return InstanceConfig(
      name: name,
      side: MinecraftSide.client,
      loader: ModLoader.unknown.name,
      version: "1.18.1",
      javaVersion: 16,
      libraries: Libraries.fromList([]),
      uuid: name,
      assetsID: "1.18",
    );
  }

  /// 使用 安裝檔UUID來建立 [InstanceConfig]
  static InstanceConfig? fromUUID(String instanceUUID) {
    return InstanceConfig.fromFile(
        InstanceRepository.instanceConfigFile(instanceUUID));
  }

  static InstanceConfig? fromFile(File file) {
    late InstanceConfig config;
    try {
      String source;
      try {
        source = file.readAsStringSync();
      } catch (e) {
        if (e is FileSystemException) {
          /// 當遇到檔案錯誤時將跳過載入，回傳空的安裝檔
          return null;
        } else {
          /// 如果是其他錯誤將重新拋出錯誤交給上層例外處理
          rethrow;
        }
      }

      Map data = json.decode(source);

      config = InstanceConfig(
        name: data['name'],
        side: MinecraftSide.values
            .byName(data['side'] ?? MinecraftSide.client.name),
        loader: data['loader'],
        version: data['version'],
        loaderVersion: data['loader_version'],
        javaVersion: data['java_version'],
        playTime: data['play_time'],
        lastPlay: data['last_play'],
        javaMaxRam: data['java_max_ram'],
        javaJvmArgs: data['java_jvm_args']?.cast<String>(),
        libraries: Libraries.fromList(data['libraries']),
        uuid: basename(file.parent.path),
        assetsID: data['assets_id'] ?? data['version'],
      );
    } catch (e, stackTrace) {
      logger.error(ErrorType.instance, e, stackTrace: stackTrace);
      config = InstanceConfig.unknown(file);

      try {
        config.storage.setItem("error", {
          /// 新增安裝檔錯誤資訊
          "stack_trace": stackTrace.toString(),
          "message": e.toString(),
          "source_instance_config": file.readAsStringSync()
        });
      } catch (e) {}

      Future.delayed(Duration.zero, () {
        showDialog(
            context: navigator.context,
            builder: (context) => AlertDialog(
                  title:
                      I18nText("gui.error.info", textAlign: TextAlign.center),
                  content: I18nText("instance.error.format",
                      args: {"error": e.toString()},
                      textAlign: TextAlign.center),
                  actions: const [OkClose()],
                ));
      });
    }
    return config;
  }

  void createConfigFile() => storage.save();
}
