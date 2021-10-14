// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Model/Libraries.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Screen/Account.dart';
import 'package:rpmlauncher/Screen/CheckAssets.dart';
import 'package:rpmlauncher/Screen/MojangAccount.dart';
import 'package:rpmlauncher/Screen/RefreshMSToken.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/CheckDialog.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/main.dart';

class Instance {
  /// 安裝檔的名稱
  String get name => config.name;

  /// 安裝檔的資料夾名稱
  final String directoryName;

  /// 安裝檔的設定物件
  InstanceConfig get config => InstanceConfig.fromIntanceDir(directoryName);

  /// 安裝檔的資料夾
  Directory get directory => InstanceRepository.getInstanceDir(directoryName);

  /// 安裝檔的資料夾路徑
  String get path => directory.path;

  Instance(this.directoryName);

  Future<void> launcher() async {
    if (account.getCount() == 0) {
      return showDialog(
        barrierDismissible: false,
        context: navigator.context,
        builder: (context) => AlertDialog(
            title: Text(i18n.format('gui.error.info')),
            content: Text(i18n.format('account.null')),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    navigator.pushNamed(AccountScreen.route);
                  },
                  child: Text(i18n.format('gui.login')))
            ]),
      );
    }
    Map Account = account.getByIndex(account.getIndex());
    showDialog(
        barrierDismissible: false,
        context: navigator.context,
        builder: (context) => FutureBuilder(
            future: utility.ValidateAccount(Account),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (!snapshot.data) {
                  //如果帳號已經過期
                  return AlertDialog(
                      title: Text(i18n.format('gui.error.info')),
                      content: Text(i18n.format('account.expired')),
                      actions: [
                        ElevatedButton(
                            onPressed: () {
                              if (Account['Type'] == account.Microsoft) {
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) =>
                                        RefreshMsTokenScreen());
                              } else if (Account['Type'] == account.Mojang) {
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) => MojangAccount(
                                        AccountEmail: Account["Account"]));
                              }
                            },
                            child: Text(i18n.format('account.again')))
                      ]);
                } else {
                  //如果帳號未過期
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    navigator.pop();
                    utility.JavaCheck(hasJava: () {
                      showDialog(
                          context: navigator.context,
                          builder: (context) => CheckAssetsScreen(
                                InstanceDir: directory,
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
    utility.OpenFileManager(directory);
  }

  void edit() {
    utility.OpenNewWindow(RouteSettings(
      name: "/instance/${basename(path)}/edit",
    ));
  }

  Future<void> copy() async {
    if (InstanceRepository.instanceConfigFile(
            "$path (${i18n.format("gui.copy")})")
        .existsSync()) {
      showDialog(
        context: navigator.context,
        builder: (context) {
          return AlertDialog(
            title: Text(i18n.format("gui.copy.failed")),
            content: Text("Can't copy file because file already exists"),
            actions: [
              TextButton(
                child: Text(i18n.format("gui.confirm")),
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
                  "$path (${i18n.format("gui.copy")})")
              .absolute
              .path);
      var NewInstanceConfig = json.decode(InstanceRepository.instanceConfigFile(
              "$path (${i18n.format("gui.copy")})")
          .readAsStringSync());
      NewInstanceConfig["name"] =
          NewInstanceConfig["name"] + "(${i18n.format("gui.copy")})";
      InstanceRepository.instanceConfigFile(
              "$path (${i18n.format("gui.copy")})")
          .writeAsStringSync(json.encode(NewInstanceConfig));
      navigator.setState(() {});
    }
  }

  Future<void> delete() async {
    showDialog(
      context: navigator.context,
      builder: (context) {
        return CheckDialog(
          title: i18n.format("gui.instance.delete"),
          content: i18n.format('gui.instance.delete.tips'),
          onPressedOK: () {
            Navigator.of(context).pop();
            try {
              directory.deleteSync(recursive: true);
            } on FileSystemException {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text(i18n.format('gui.error.info')),
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
class InstanceConfig {
  final File file;

  /// 原始資料
  Map _rawData = {};

  operator []=(String key, dynamic value) => _changeValue(key, value);
  operator [](String key) => _get(key);

  /// 安裝檔案名稱
  String get name => _rawData['name'] ?? "Name not found";

  /// 安裝檔模組載入器，可以是 forge、fabric、vanilla、unknown
  String get loader => _rawData['loader'];

  /// 模組載入器的枚舉值 [ModLoaders]
  ModLoaders get loaderEnum => ModLoaderUttily.getByString(loader);

  /// 安裝檔的遊戲版本
  String get version => _rawData['version'];

  /// 安裝檔的模組載入器版本
  String? get loaderVersion => _rawData['loader_version'];

  /// 安裝檔需要的Java版本，可以是 8 或 16
  int get javaVersion => _rawData['java_version'];

  /// 安裝檔的遊玩時間，預設為 0
  int get playTime => _rawData['play_time'] ?? 0;

  /// 安裝檔最後遊玩的時間，預設為 null
  int? get lastPlay => _rawData['last_play'];

  /// 安裝檔最多可以使用的記憶體，預設為 null
  double? get javaMaxRam => _rawData['java_max_ram'];

  /// 安裝檔的JVM (Java 虛擬機器) 參數，預設為 null
  List<String>? get javaJvmArgs => _rawData['java_jvm_args'];

  Libraries get libraries => Libraries.fromList(_rawData['libraries'] ?? []);

  set name(String value) => _changeValue('name', value);
  set loader(String value) => _changeValue('loader', value);
  set version(String value) => _changeValue('version', value);
  set loaderVersion(String? value) => _changeValue('loader_version', value);
  set javaVersion(int value) => _changeValue('java_version', value);
  set playTime(int? value) => _changeValue('play_time', value ?? 0);
  set lastPlay(int? value) => _changeValue('last_play', value ?? 0);
  set javaMaxRam(double? value) => _changeValue('java_max_ram', value);
  set javaJvmArgs(List<String>? value) => _changeValue('java_jvm_args', value);
  set libraries(Libraries value) => _changeValue('libraries', value.toJson());

  InstanceConfig(
      {required this.file,
      required String name,
      required String loader,
      required String version,
      String? loaderVersion,
      required int javaVersion,
      int? playTime,
      int? lastPlay,
      double? javaMaxRam,
      List<String>? javaJvmArgs,
      Libraries? libraries}) {
    _rawData['name'] = name;
    _rawData['loader'] = loader;
    _rawData['version'] = version;
    _rawData['loader_version'] = loaderVersion;
    _rawData['java_version'] = javaVersion;
    _rawData['play_time'] = playTime;
    _rawData['last_play'] = lastPlay;
    _rawData['java_max_ram'] = javaMaxRam;
    _rawData['java_jvm_args'] = javaJvmArgs;
    _rawData['libraries'] = (libraries ?? Libraries([])).toJson();
  }

  void remove(String key) {
    _rawData.remove(key);
    _save();
  }

  void change(String key, dynamic value) => _changeValue(key, value);

  /// 儲存變更並且更新安裝檔設定檔案
  void _changeValue(String key, dynamic value) {
    _rawData[key] = value;
    _save();
  }

  /// 儲存安裝檔設定檔案
  void _save() {
    file.writeAsStringSync(json.encode(_rawData));
  }

  /// 重新從檔案中載入設定
  void _update() {
    _rawData = json.decode(file.readAsStringSync());
  }

  void _get(String key) {
    _update();
    return _rawData[key];
  }

  /// 取得安裝檔設定的 Map
  Map toMap() => _rawData;

  /// 取得安裝檔設定的 String，為 json 格式
  @override
  String toString() => toJson();

  String toJson() => json.encode(_rawData);

  /// 使用 安裝檔名稱來建立 [InstanceConfig]
  factory InstanceConfig.fromIntanceDir(String InstanceDirName) {
    return InstanceConfig.fromFile(
        InstanceRepository.instanceConfigFile(InstanceDirName));
  }

  factory InstanceConfig.fromFile(File file) {
    Map _data = json.decode(file.readAsStringSync());
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
          javaJvmArgs: _data['java_jvm_args'],
          libraries: Libraries.fromList(_data['libraries']));
    } catch (e) {
      Future.delayed(Duration.zero, () {
        showDialog(
            context: navigator.context,
            builder: (context) => AlertDialog(
                  title:
                      i18nText("gui.error.info", textAlign: TextAlign.center),
                  content: Text("偵測到您的安裝檔格式錯誤，請嘗試重新建立安裝檔，如仍然失敗請回報錯誤\n錯誤訊息:\n$e",
                      textAlign: TextAlign.center),
                  actions: [OkClose()],
                ));
      });
    }
    return _config;
  }
}
