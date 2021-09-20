import 'dart:io' as io;

import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Model/JvmArgs.dart';
import 'package:rpmlauncher/Model/ViewOptions.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/OptionsView.dart';
import 'package:system_info/system_info.dart';

import '../main.dart';

class SettingScreen_ extends State<SettingScreen> {
  late Color PrimaryColor;
  late Color ValidRam;
  late Color ValidWidth;
  late Color ValidHeight;
  late Color ValidLogLength;

  bool AutoJava = true;
  bool CheckAssets = true;
  bool ShowLog = false;
  bool AutoDependencies = true;

  VersionTypes UpdateChannel =
      Updater.getVersionTypeFromString(Config.getValue('update_channel'));

  String JavaVersion = "8";
  List<String> JavaVersions = ["8", "16"];
  int selectedIndex = 0;
  final RamMB = (SysInfo.getTotalPhysicalMemory()) / 1024 / 1024;

  @override
  void initState() {
    JavaController.text = Config.getValue("java_path_${JavaVersion}");
    AutoJava = Config.getValue("auto_java");
    CheckAssets = Config.getValue("check_assets");
    ShowLog = Config.getValue("show_log");
    AutoDependencies = Config.getValue("auto_dependencies");
    MaxRamController.text = Config.getValue("java_max_ram").toString();
    GameWidthController.text = Config.getValue("game_width").toString();
    GameHeightController.text = Config.getValue("game_height").toString();
    MaxLogLengthController.text = Config.getValue("max_log_length").toString();
    JvmArgsController.text =
        JvmArgs.fromList(Config.getValue("java_jvm_args")).args;
    PrimaryColor = ThemeUtility.getTheme().colorScheme.primary;
    ValidRam = PrimaryColor;
    ValidWidth = PrimaryColor;
    ValidHeight = PrimaryColor;
    ValidLogLength = PrimaryColor;

    super.initState();
  }

  var title_ = TextStyle(
    fontSize: 20.0,
    color: Colors.lightBlue,
  );
  var title2_ = TextStyle(
    fontSize: 20.0,
    color: Colors.amberAccent,
  );
  TextEditingController JavaController = TextEditingController();
  TextEditingController MaxRamController = TextEditingController();
  TextEditingController JvmArgsController = TextEditingController();

  TextEditingController GameWidthController = TextEditingController();
  TextEditingController GameHeightController = TextEditingController();

  TextEditingController MaxLogLengthController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(i18n.format("settings.title")),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            tooltip: i18n.format("gui.back"),
            onPressed: () {
              navigator.pop();
            },
          ),
        ),
        body: OptionsView(
          gripSize: 3,
          weights: [0.2],
          optionWidgets: (StateSetter _setState) {
            return [
              ListView(
                children: [
                  Text(
                    i18n.format("settings.java.path"),
                    style: title_,
                    textAlign: TextAlign.center,
                  ),
                  Row(
                    children: [
                      Text("    ${i18n.format("java.version")}: ",
                          style: title_),
                      DropdownButton<String>(
                        value: JavaVersion,
                        onChanged: (String? newValue) {
                          _setState(() {
                            JavaVersion = newValue!;
                            JavaController.text =
                                Config.getValue("java_path_${JavaVersion}");
                          });
                        },
                        items: JavaVersions.map<DropdownMenuItem<String>>(
                            (String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                style: TextStyle(fontSize: 20),
                                textAlign: TextAlign.center),
                          );
                        }).toList(),
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Expanded(
                          child: TextField(
                        textAlign: TextAlign.center,
                        controller: JavaController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: i18n.format("settings.java.path"),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: PrimaryColor, width: 5.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: PrimaryColor, width: 3.0),
                          ),
                        ),
                      )),
                      SizedBox(
                        width: 12,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            utility.OpenJavaSelectScreen(context).then((value) {
                              if (value[0]) {
                                Config.change(
                                    "java_path_$JavaVersion", value[1]);
                                JavaController.text =
                                    Config.getValue("java_path_${JavaVersion}");
                              }
                            });
                          },
                          child: Text(
                            i18n.format("settings.java.path.select"),
                            style: TextStyle(fontSize: 18),
                          )),
                      SizedBox(
                        width: 12,
                      ),
                    ],
                  ),
                  Column(children: [
                    Text(i18n.format("settings.java.auto"), style: title_),
                    Switch(
                        value: AutoJava,
                        onChanged: (value) {
                          _setState(() {
                            AutoJava = !AutoJava;
                            Config.change("auto_java", AutoJava);
                          });
                        })
                  ]),
                  ListTile(
                      title: Column(children: [
                    Text(
                      i18n.format("settings.java.ram.max"),
                      style: title_,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                        "${i18n.format("settings.java.ram.physical")} ${RamMB.toStringAsFixed(0)} MB")
                  ])),
                  ListTile(
                    title: TextField(
                      textAlign: TextAlign.center,
                      controller: MaxRamController,
                      decoration: InputDecoration(
                        hintText: "4096",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: ValidRam, width: 5.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: ValidRam, width: 3.0),
                        ),
                      ),
                      onChanged: (value) async {
                        if (int.tryParse(value) == null ||
                            int.parse(value) > RamMB) {
                          ValidRam = Colors.red;
                        } else {
                          Config.change("java_max_ram", int.parse(value));
                          ValidRam = PrimaryColor;
                        }
                        _setState(() {});
                      },
                    ),
                  ),
                  Text(
                    i18n.format('settings.java.jvm.args'),
                    style: title_,
                    textAlign: TextAlign.center,
                  ),
                  ListTile(
                    title: TextField(
                      textAlign: TextAlign.center,
                      controller: JvmArgsController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: PrimaryColor, width: 5.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: PrimaryColor, width: 3.0),
                        ),
                      ),
                      onChanged: (value) async {
                        Config.change(
                            'java_jvm_args', JvmArgs(args: value).toList());
                        _setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              ListView(
                children: [
                  Column(
                    children: [
                      SelectorLanguageWidget(setWidgetState: _setState),
                      Text(
                        i18n.format("settings.appearance.theme"),
                        style: title_,
                      ),
                      SelectorThemeWidget(
                        ThemeString: ThemeUtility.toI18nString(
                            ThemeUtility.getThemeEnumByID(
                                Config.getValue('theme_id'))),
                        setWidgetState: _setState,
                      ),
                      Text(
                        i18n.format("settings.appearance.window.size.title"),
                        style: title_,
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller: GameWidthController,
                              decoration: InputDecoration(
                                hintText: "854",
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: ValidWidth, width: 3.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: ValidWidth, width: 2.0),
                                ),
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                              ),
                              onChanged: (value) async {
                                if (int.tryParse(value) == null) {
                                  ValidWidth = Colors.red;
                                } else {
                                  Config.change("game_width", int.parse(value));
                                  ValidWidth = PrimaryColor;
                                }
                                _setState(() {});
                              },
                            ),
                          ),
                          SizedBox(
                            width: 12,
                          ),
                          Icon(Icons.clear),
                          SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller: GameHeightController,
                              decoration: InputDecoration(
                                hintText: "480",
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ValidHeight, width: 3.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ValidHeight, width: 2.0),
                                ),
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                              ),
                              onChanged: (value) async {
                                if (int.tryParse(value) == null) {
                                  ValidHeight = Colors.red;
                                } else {
                                  Config.change(
                                      "game_height", int.parse(value));
                                  ValidHeight = PrimaryColor;
                                }
                                _setState(() {});
                              },
                            ),
                          ),
                          SizedBox(
                            width: 12,
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
              ListView(
                children: [
                  Text("如果您不了解此頁面的用途，請不要調整此頁面的選項",
                      style: TextStyle(color: Colors.red, fontSize: 30),
                      textAlign: TextAlign.center),
                  Text(i18n.format("settings.advanced.assets.check"),
                      style: title_, textAlign: TextAlign.center),
                  Switch(
                      value: CheckAssets,
                      onChanged: (value) {
                        _setState(() {
                          CheckAssets = !CheckAssets;
                          Config.change("check_assets", CheckAssets);
                        });
                      }),
                  Text("是否啟用控制台輸出遊戲日誌",
                      style: title_, textAlign: TextAlign.center),
                  Switch(
                      value: ShowLog,
                      onChanged: (value) {
                        _setState(() {
                          ShowLog = !ShowLog;
                          Config.change("show_log", ShowLog);
                        });
                      }),
                  Text("是否自動下載前置模組",
                      style: title_, textAlign: TextAlign.center),
                  Switch(
                      value: AutoDependencies,
                      onChanged: (value) {
                        _setState(() {
                          AutoDependencies = !AutoDependencies;
                          Config.change("auto_dependencies", AutoDependencies);
                        });
                      }),
                  Text("RPMLauncher 更新通道",
                      style: title_, textAlign: TextAlign.center),
                  Center(
                    child: StatefulBuilder(builder: (context, _setState) {
                      return DropdownButton(
                          value: UpdateChannel,
                          items: [
                            DropdownMenuItem(
                              value: VersionTypes.stable,
                              child: Text(
                                  Updater.toI18nString(VersionTypes.stable)),
                            ),
                            DropdownMenuItem(
                              value: VersionTypes.dev,
                              child:
                                  Text(Updater.toI18nString(VersionTypes.dev)),
                            ),
                          ],
                          onChanged: (dynamic Channel) async {
                            _setState(() {
                              UpdateChannel = Channel;
                              Config.change('update_channel',
                                  Updater.toStringFromVersionType(Channel));
                            });
                          });
                    }),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                      ),
                      Text(i18n.format("settings.advanced.max.log"),
                          style: title_, textAlign: TextAlign.center),
                      SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: TextField(
                          textAlign: TextAlign.center,
                          controller: MaxLogLengthController,
                          decoration: InputDecoration(
                            hintText: "500",
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: ValidLogLength, width: 3.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: ValidLogLength, width: 2.0),
                            ),
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                          onChanged: (value) async {
                            if (int.tryParse(value) == null) {
                              ValidLogLength = Colors.red;
                            } else {
                              Config.change("max_log_length", int.parse(value));
                              ValidLogLength = PrimaryColor;
                            }
                            _setState(() {});
                          },
                        ),
                      ),
                      SizedBox(
                        width: 24,
                      ),
                    ],
                  )
                ],
              ),
              ListView(
                children: [
                  Text("如果您不了解此頁面的用途，請不要調整此頁面的選項",
                      style: TextStyle(color: Colors.red, fontSize: 30),
                      textAlign: TextAlign.center),
                  SizedBox(
                    height: 12,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                          onPressed: () {
                            dataHome.deleteSync(recursive: true);
                          },
                          child: Text("刪除啟動器的所有檔案", style: title_)),
                      SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      TextButton(
                          onPressed: () {
                            dataHome.deleteSync(recursive: true);
                          },
                          child: Text("刪除啟動器資料主目錄", style: title_)),
                      SizedBox(
                        height: 12,
                      ),
                      TextButton(
                          onPressed: () {
                            GameRepository.getVersionsRootDir()
                                .deleteSync(recursive: true);
                          },
                          child: Text("刪除函式庫與參數檔案", style: title_))
                    ],
                  ),
                ],
              ),
            ];
          },
          options: () {
            return ViewOptions([
              ViewOption(
                title: i18n.format("settings.java.title"),
                icon: Icon(
                  Icons.code_outlined,
                ),
              ),
              ViewOption(
                title: i18n.format("settings.appearance.title"),
                icon: Icon(
                  Icons.web_asset_outlined,
                ),
              ),
              ViewOption(
                title: i18n.format("settings.advanced.title"),
                icon: Icon(
                  Icons.settings,
                ),
              ),
              ViewOption(
                title: "除錯選項",
                icon: Icon(
                  Icons.bug_report,
                ),
              )
            ]);
          },
        ));
  }
}

class SettingScreen extends StatefulWidget {
  @override
  SettingScreen_ createState() => SettingScreen_();
}
