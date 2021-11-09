import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Game/Account.dart';
import 'package:rpmlauncher/Model/Game/Libraries.dart';
import 'package:rpmlauncher/Model/IO/JsonDataClass.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Screen/Account.dart';
import 'package:rpmlauncher/Screen/CheckAssets.dart';
import 'package:rpmlauncher/Screen/MojangAccount.dart';
import 'package:rpmlauncher/Screen/RefreshMSToken.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Widget/CheckDialog.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/main.dart';
import 'package:uuid/uuid.dart';

class Instance {
  /// 安裝檔的名稱
  String get name => config.name;

  /// 安裝檔的UUID
  final String uuid;

  /// 安裝檔的設定物件
  InstanceConfig get config => InstanceConfig.fromUUID(uuid);

  /// 安裝檔的資料夾
  Directory get directory => InstanceRepository.getInstanceDir(uuid);

  /// 安裝檔的資料夾路徑
  String get path => directory.path;

  Instance(this.uuid);

  Future<void> launcher() async {
    if (Account.getCount() == 0) {
      return showDialog(
        barrierDismissible: false,
        context: navigator.context,
        builder: (context) => AlertDialog(
            title: Text(I18n.format('gui.error.info')),
            content: Text(I18n.format('account.null')),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    navigator.pushNamed(AccountScreen.route);
                  },
                  child: Text(I18n.format('gui.login')))
            ]),
      );
    }
    Account account = Account.getByIndex(Account.getIndex());
    showDialog(
        barrierDismissible: false,
        context: navigator.context,
        builder: (context) => FutureBuilder(
            future: Uttily.validateAccount(account),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (!snapshot.data) {
                  //如果帳號已經過期
                  return AlertDialog(
                      title: Text(I18n.format('gui.error.info')),
                      content: Text(I18n.format('account.expired')),
                      actions: [
                        ElevatedButton(
                            onPressed: () {
                              if (account.type == AccountType.microsoft) {
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) =>
                                        RefreshMsTokenScreen());
                              } else if (account.type == AccountType.mojang) {
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) => MojangAccount(
                                        accountEmail: account.email ?? ""));
                              }
                            },
                            child: Text(I18n.format('account.again')))
                      ]);
                } else {
                  //如果帳號未過期
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    navigator.pop();
                    Uttily.javaCheck(hasJava: () {
                      showDialog(
                          context: navigator.context,
                          builder: (context) => CheckAssetsScreen(
                                instanceDir: directory,
                              ));
                    });
                  });

                  return SizedBox.shrink();
                }
              } else {
                return Center(child: RWLLoading());
              }
            }));
  }

  void openFolder() {
    Uttily.openFileManager(directory);
  }

  void edit() {
    Uttily.openNewWindow(RouteSettings(
      name: "/instance/${basename(path)}/edit",
    ));
  }

  Future<void> copy() async {
    if (InstanceRepository.instanceConfigFile(
            "$path (${I18n.format("gui.copy")})")
        .existsSync()) {
      showDialog(
        context: navigator.context,
        builder: (context) {
          return AlertDialog(
            title: Text(I18n.format("gui.copy.failed")),
            content: Text("Can't copy file because file already exists"),
            actions: [
              TextButton(
                child: Text(I18n.format("gui.confirm")),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      copyPathSync(
          path,
          InstanceRepository.getInstanceDir(
                  "$path (${I18n.format("gui.copy")})")
              .absolute
              .path);
      InstanceConfig newInstanceConfig = InstanceRepository.instanceConfig(
          "$path (${I18n.format("gui.copy")})");
      newInstanceConfig.name =
          Uttily.duplicateNameHandler(newInstanceConfig.name);
      InstanceRepository.instanceConfigFile(
              "$path (${I18n.format("gui.copy")})")
          .writeAsStringSync(newInstanceConfig.rawDataString);
    }
  }

  Future<void> delete() async {
    showDialog(
      context: navigator.context,
      builder: (context) {
        return CheckDialog(
          title: I18n.format("gui.instance.delete"),
          content: I18n.format('gui.instance.delete.tips'),
          onPressedOK: () {
            Navigator.of(context).pop();
            try {
              directory.deleteSync(recursive: true);
            } on FileSystemException {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text(I18n.format('gui.error.info')),
                        content: Text("刪除安裝檔時發生未知錯誤，可能是該資料夾被其他應用程式存取或其他錯誤。"),
                        actions: [OkClose()],
                      ));
            }
          },
        );
      },
    );
  }
}

/// 安裝檔設定類別
class InstanceConfig extends JsonDataMap {
  /// 安裝檔案名稱
  String get name => rawData['name'] ?? "Name not found";

  /// 安裝檔的UUID
  String get uuid => rawData['uuid'];

  /// 安裝檔模組載入器，可以是 forge、fabric、vanilla、unknown
  String get loader => rawData['loader'];

  /// 模組載入器的枚舉值 [ModLoaders]
  ModLoaders get loaderEnum => ModLoaderUttily.getByString(loader);

  /// 安裝檔的遊戲版本
  String get version => rawData['version'];

  /// 可比較大小的遊戲版本
  Version get comparableVersion => Uttily.parseMCComparableVersion(version);

  /// 安裝檔的模組載入器版本
  String? get loaderVersion => rawData['loader_version'];

  /// 安裝檔需要的Java版本，可以是 8 或 16
  int get javaVersion => rawData['java_version'];

  /// 安裝檔的遊玩時間，預設為 0
  int get playTime => rawData['play_time'] ?? 0;

  /// 安裝檔最後遊玩的時間，預設為 null
  int? get lastPlay => rawData['last_play'];

  String get lastPlayLocalString => lastPlay == null
      ? I18n.format('datas.found.not')
      : DateFormat.yMMMMEEEEd(Platform.localeName)
          .add_jms()
          .format(DateTime.fromMillisecondsSinceEpoch(lastPlay!));

  /// 安裝檔最多可以使用的記憶體，預設為 null
  double? get javaMaxRam => rawData['java_max_ram'];

  /// 安裝檔的JVM (Java 虛擬機器) 參數，預設為 null
  List<String>? get javaJvmArgs => rawData['java_jvm_args'];

  Libraries get libraries => Libraries.fromList(rawData['libraries'] ?? []);

  set name(String value) => changeValue('name', value);
  set loader(String value) => changeValue('loader', value);
  set version(String value) => changeValue('version', value);
  set loaderVersion(String? value) => changeValue('loader_version', value);
  set javaVersion(int value) => changeValue('java_version', value);
  set playTime(int? value) => changeValue('play_time', value ?? 0);
  set lastPlay(int? value) => changeValue('last_play', value ?? 0);
  set javaMaxRam(double? value) => changeValue('java_max_ram', value);
  set javaJvmArgs(List<String>? value) => changeValue('java_jvm_args', value);
  set libraries(Libraries value) => changeValue('libraries', value.toJson());

  InstanceConfig(
      {required File file,
      required String name,
      required String loader,
      required String version,
      required int javaVersion,
      String? uuid,
      String? loaderVersion,
      int? playTime,
      int? lastPlay,
      double? javaMaxRam,
      List<String>? javaJvmArgs,
      Libraries? libraries})
      : super(file) {
    rawData['uuid'] = uuid ?? Uuid().v4();

    rawData['name'] = name;
    rawData['loader'] = loader;
    rawData['version'] = version;
    rawData['loader_version'] = loaderVersion;
    rawData['java_version'] = javaVersion;
    rawData['play_time'] = playTime;
    rawData['last_play'] = lastPlay;
    rawData['java_max_ram'] = javaMaxRam;
    rawData['java_jvm_args'] = javaJvmArgs;
    rawData['libraries'] = (libraries ?? Libraries([])).toJson();
  }

  /// 使用 安裝檔名稱來建立 [InstanceConfig]
  factory InstanceConfig.fromUUID(String instanceUUID) {
    return InstanceConfig.fromFile(InstanceRepository.instanceConfigFile(instanceUUID));
  }

  factory InstanceConfig.fromFile(File file) {
    Map _data = json.decode(file.readAsStringSync());

    /// 舊版安裝檔格式沒有UUID，暫時使用 name 代替
    if (_data['uuid'] == null) {
      _data['uuid'] = _data['name'];
    }

    late InstanceConfig _config;
    try {
      _config = InstanceConfig(
        file: file,
        name: _data['name'],
        loader: _data['loader'],
        version: _data['version'],
        loaderVersion: _data['loader_version'],
        javaVersion: _data['java_version'],
        playTime: _data['play_time'],
        lastPlay: _data['last_play'],
        javaMaxRam: _data['java_max_ram'],
        javaJvmArgs: _data['java_jvm_args']?.cast<String>(),
        libraries: Libraries.fromList(_data['libraries']),
        uuid: _data['uuid'],
      );
    } catch (e) {
      logger.error(ErrorType.instance, e);
      Future.delayed(Duration.zero, () {
        showDialog(
            context: navigator.context,
            builder: (context) => AlertDialog(
                  title:
                      I18nText("gui.error.info", textAlign: TextAlign.center),
                  content: Text("偵測到您的安裝檔格式錯誤，請嘗試重新建立安裝檔，如仍然失敗請回報錯誤\n錯誤訊息:\n$e",
                      textAlign: TextAlign.center),
                  actions: [OkClose()],
                ));
      });
    }
    return _config;
  }

  void createConfigFile() {
    createFile();
    dataFile.writeAsStringSync(rawDataString);
  }
}
