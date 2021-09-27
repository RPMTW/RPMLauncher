// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
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

class InstanceConfig {
  final File file;

  Map get rawData => json.decode(file.readAsStringSync());
  set rawData(Map map) {
    rawData = map;
    _save();
  }

  String get name => rawData['name'] ?? "Name not found";
  String get loader => rawData['loader'];
  ModLoaders get loaderEnum => ModLoaderUttily.getByString(loader);
  String get version => rawData['version'];
  String get loaderVersion => rawData['loader_version'];
  int get javaVersion => rawData['java_version'];
  int get playTime => rawData['play_time'];
  int? get lastPlay => rawData['last_play'];
  int? get javaMaxRam => rawData['java_max_ram'];
  List? get javaJvmArgs => rawData['java_jvm_args'];

  set name(String value) => _changeValue('name', value);
  set loader(String value) => _changeValue('loader', value);
  set version(String value) => _changeValue('version', value);
  set loaderVersion(String value) => _changeValue('loader_version', value);
  set javaVersion(int value) => _changeValue('java_version', value);
  set playTime(int? value) => _changeValue('play_time', value ?? 0);
  set lastPlay(int? value) => _changeValue('last_play', value ?? 0);
  set javaMaxRam(int? value) => _changeValue('java_max_ram', value);
  set javaJvmArgs(List? value) => _changeValue('java_jvm_args', value);

  InstanceConfig(this.file);

  void _changeValue(String key, dynamic value) {
    rawData[key] = value;
    _save();
  }

  void _save() {
    file.writeAsStringSync(json.encode(rawData));
  }

  Map toMap() => rawData;

  factory InstanceConfig.fromIntanceDir(String InstanceDirName) {
    return InstanceConfig(
        InstanceRepository.instanceConfigFile(InstanceDirName));
  }
}
