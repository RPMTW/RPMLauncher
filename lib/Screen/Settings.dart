import 'dart:io' as io;

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Model/JvmArgs.dart';
import 'package:rpmlauncher/Model/ViewOptions.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/View/OptionsView.dart';
import 'package:rpmlauncher/path.dart';
import 'package:system_info/system_info.dart';

import '../main.dart';

class SettingScreen_ extends State<SettingScreen> {
  Color get PrimaryColor => ThemeUtility.getTheme().colorScheme.primary;
  late Color ValidWidth;
  late Color ValidHeight;
  late Color ValidLogLength;
  late Color ValidRam;

  bool AutoJava = true;
  bool CheckAssets = true;
  bool ShowLog = false;
  late bool AutoDependencies;
  late bool AutoFullScreen;
  double nowMaxRamMB = Config.getValue("java_max_ram");

  VersionTypes UpdateChannel =
      Updater.getVersionTypeFromString(Config.getValue('update_channel'));

  String JavaVersion = "8";
  List<String> JavaVersions = ["8", "16"];
  int selectedIndex = 0;

  late final double RamMB;

  @override
  void initState() {
    JavaController.text = Config.getValue("java_path_$JavaVersion");
    AutoJava = Config.getValue("auto_java");
    CheckAssets = Config.getValue("check_assets");
    ShowLog = Config.getValue("show_log");
    AutoDependencies = Config.getValue("auto_dependencies");
    AutoFullScreen = LauncherInfo.autoFullScreen;
    GameWidthController.text = Config.getValue("game_width").toString();
    GameHeightController.text = Config.getValue("game_height").toString();
    MaxLogLengthController.text = Config.getValue("max_log_length").toString();
    JvmArgsController.text =
        JvmArgs.fromList(Config.getValue("java_jvm_args")).args;
    ValidWidth = PrimaryColor;
    ValidHeight = PrimaryColor;
    ValidLogLength = PrimaryColor;
    ValidRam = PrimaryColor;

    int _ = ((SysInfo.getTotalPhysicalMemory()) / 1024 ~/ 1024);
    _ = _ - _ % 1024;

    RamMB = _.toDouble();

    super.initState();
  }

  TextStyle title_ = TextStyle(
    fontSize: 20.0,
    color: Colors.lightBlue,
  );
  TextStyle title2_ = TextStyle(
    fontSize: 20.0,
    color: Colors.amberAccent,
  );
  TextEditingController JavaController = TextEditingController();
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                      ),
                      DropdownButton<String>(
                        value: JavaVersion,
                        onChanged: (String? newValue) {
                          _setState(() {
                            JavaVersion = newValue!;
                            JavaController.text =
                                Config.getValue("java_path_$JavaVersion");
                          });
                        },
                        items: JavaVersions.map<DropdownMenuItem<String>>(
                            (String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            alignment: Alignment.center,
                            child: Text(
                                "${i18n.format("java.version")}: $value",
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
                                BorderSide(color: PrimaryColor, width: 3.0),
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
                                    Config.getValue("java_path_$JavaVersion");
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
                  Divider(),
                  SwitchListTile(
                    value: AutoJava,
                    onChanged: (value) {
                      _setState(() {
                        AutoJava = !AutoJava;
                        Config.change("auto_java", AutoJava);
                      });
                    },
                    title: Text(
                      i18n.format("settings.java.auto"),
                      style: title_,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Divider(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        i18n.format("settings.java.ram.max"),
                        style: title_,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "${i18n.format("settings.java.ram.physical")} ${RamMB.toStringAsFixed(0)} MB",
                      ),
                      Slider(
                        value: nowMaxRamMB,
                        onChanged: (double value) {
                          Config.change("java_max_ram", value);
                          ValidRam = PrimaryColor;
                          nowMaxRamMB = value;
                          _setState(() {});
                        },
                        activeColor: ValidRam,
                        min: 1024,
                        max: RamMB,
                        divisions: (RamMB ~/ 1024) - 1,
                        label: "${nowMaxRamMB.toInt()} MB",
                      ),
                    ],
                  ),
                  Divider(),
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
                      Divider(),
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
                      Divider(),
                      Text(
                        i18n.format("settings.appearance.window.size.title"),
                        style: title_,
                      ),
                      Divider(),
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
                  Divider(),
                  Text("RPMLauncher 資料儲存位置",
                      style: title_, textAlign: TextAlign.center),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(path.currentDataHome.absolute.path,
                          style: TextStyle(fontSize: 20),
                          textAlign: TextAlign.center),
                      TextButton(
                          onPressed: () async {
                            String? path = await FileSelectorPlatform.instance
                                .getDirectoryPath();

                            if (path != null) {
                              Config.change("data_home", path);
                              _setState(() {});
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => AlertDialog(
                                        title: Text("修改資料儲存位置成功，請重開本軟體才會變更完畢"),
                                        actions: [
                                          OkClose(
                                            onOk: () {
                                              io.exit(0);
                                            },
                                          )
                                        ],
                                      ));
                            }
                          },
                          child: Text("修改位置", style: TextStyle(fontSize: 22))),
                    ],
                  ),
                  Divider(),
                  SwitchListTile(
                    value: CheckAssets,
                    onChanged: (value) {
                      _setState(() {
                        CheckAssets = !CheckAssets;
                        Config.change("check_assets", CheckAssets);
                      });
                    },
                    title: i18nText("settings.advanced.assets.check",
                        style: title_, textAlign: TextAlign.center),
                  ),
                  Divider(),
                  SwitchListTile(
                    value: ShowLog,
                    onChanged: (value) {
                      _setState(() {
                        ShowLog = !ShowLog;
                        Config.change("show_log", ShowLog);
                      });
                    },
                    title: Text("是否啟用控制台輸出遊戲日誌",
                        style: title_, textAlign: TextAlign.center),
                  ),
                  Divider(),
                  SwitchListTile(
                    value: AutoDependencies,
                    onChanged: (value) {
                      _setState(() {
                        AutoDependencies = !AutoDependencies;
                        Config.change("auto_dependencies", AutoDependencies);
                      });
                    },
                    title: Text("是否自動下載前置模組",
                        style: title_, textAlign: TextAlign.center),
                  ),
                  Divider(),
                  SwitchListTile(
                    value: AutoFullScreen,
                    onChanged: (value) {
                      _setState(() {
                        AutoFullScreen = !AutoFullScreen;
                        Config.change("auto_full_screen", AutoFullScreen);
                      });
                    },
                    title: Text("啟動 RPMLauncher 時是否自動將視窗最大化",
                        style: title_, textAlign: TextAlign.center),
                  ),
                  Divider(),
                  ListTile(
                    title: Text("RPMLauncher 更新通道",
                        style: title_, textAlign: TextAlign.center),
                    trailing: StatefulBuilder(builder: (context, _setState) {
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
                  Divider(),
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
                  ),
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
  static const String route = "/settings";

  @override
  SettingScreen_ createState() => SettingScreen_();
}
