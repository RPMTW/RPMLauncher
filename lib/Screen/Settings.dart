import 'dart:io' as io;

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Model/JvmArgs.dart';
import 'package:rpmlauncher/Model/ViewOptions.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/View/OptionsView.dart';
import 'package:rpmlauncher/Utility/RPMPath.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

import '../main.dart';

class _SettingScreenState extends State<SettingScreen> {
  Color get primaryColor => ThemeUtility.getTheme().colorScheme.primary;
  late Color validWidth;
  late Color validHeight;
  late Color validLogLength;

  late bool autoJava;
  late bool checkAssets;
  late bool showLog;
  late bool autoDependencies;
  late bool autoFullScreen;
  late bool validateAccount;
  double nowMaxRamMB = Config.getValue("java_max_ram");

  VersionTypes updateChannel =
      Updater.getVersionTypeFromString(Config.getValue('update_channel'));

  String javaVersion = "8";
  List<String> javaVersions = ["8", "16"];
  int selectedIndex = 0;

  @override
  void initState() {
    javaController.text = Config.getValue("java_path_$javaVersion");
    autoJava = Config.getValue("auto_java");
    validateAccount = Config.getValue("validate_account");
    checkAssets = Config.getValue("check_assets");
    showLog = Config.getValue("show_log");
    autoDependencies = Config.getValue("auto_dependencies");
    autoFullScreen = LauncherInfo.autoFullScreen;
    gameWidthController.text = Config.getValue("game_width").toString();
    gameHeightController.text = Config.getValue("game_height").toString();
    maxLogLengthController.text = Config.getValue("max_log_length").toString();
    jvmArgsController.text =
        JvmArgs.fromList(Config.getValue("java_jvm_args")).args;
    validWidth = primaryColor;
    validHeight = primaryColor;
    validLogLength = primaryColor;
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
  TextEditingController javaController = TextEditingController();
  TextEditingController jvmArgsController = TextEditingController();

  TextEditingController gameWidthController = TextEditingController();
  TextEditingController gameHeightController = TextEditingController();

  TextEditingController maxLogLengthController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(I18n.format("settings.title")),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            tooltip: I18n.format("gui.back"),
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
                    I18n.format("settings.java.path"),
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
                        value: javaVersion,
                        onChanged: (String? newValue) {
                          _setState(() {
                            javaVersion = newValue!;
                            javaController.text =
                                Config.getValue("java_path_$javaVersion");
                          });
                        },
                        items: javaVersions
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            alignment: Alignment.center,
                            child: Text(
                                "${I18n.format("java.version")}: $value",
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
                        controller: javaController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: I18n.format("settings.java.path"),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: primaryColor, width: 3.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: primaryColor, width: 3.0),
                          ),
                        ),
                      )),
                      SizedBox(
                        width: 12,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            Uttily.openJavaSelectScreen(context).then((value) {
                              if (value[0]) {
                                Config.change(
                                    "java_path_$javaVersion", value[1]);
                                javaController.text =
                                    Config.getValue("java_path_$javaVersion");
                              }
                            });
                          },
                          child: Text(
                            I18n.format("settings.java.path.select"),
                            style: TextStyle(fontSize: 18),
                          )),
                      SizedBox(
                        width: 12,
                      ),
                    ],
                  ),
                  Divider(),
                  SwitchListTile(
                    value: autoJava,
                    onChanged: (value) {
                      _setState(() {
                        autoJava = !autoJava;
                        Config.change("auto_java", autoJava);
                      });
                    },
                    title: Text(
                      I18n.format("settings.java.auto"),
                      style: title_,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Divider(),
                  FutureBuilder<int>(
                      future: Uttily.getTotalPhysicalMemory(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          double ramMB = snapshot.data!.toDouble();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                I18n.format("settings.java.ram.max"),
                                style: title_,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                "${I18n.format("settings.java.ram.physical")} ${ramMB.toStringAsFixed(0)} MB",
                              ),
                              Slider(
                                value: nowMaxRamMB,
                                onChanged: (double value) {
                                  Config.change("java_max_ram", value);
                                  nowMaxRamMB = value;
                                  _setState(() {});
                                },
                                activeColor: primaryColor,
                                min: 1024,
                                max: ramMB,
                                divisions: (ramMB ~/ 1024) - 1,
                                label: "${nowMaxRamMB.toInt()} MB",
                              ),
                            ],
                          );
                        } else {
                          return RWLLoading();
                        }
                      }),
                  Divider(),
                  Text(
                    I18n.format('settings.java.jvm.args'),
                    style: title_,
                    textAlign: TextAlign.center,
                  ),
                  ListTile(
                    title: TextField(
                      textAlign: TextAlign.center,
                      controller: jvmArgsController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: primaryColor, width: 5.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: primaryColor, width: 3.0),
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
                        I18n.format("settings.appearance.theme"),
                        style: title_,
                      ),
                      SelectorThemeWidget(
                        themeString: ThemeUtility.toI18nString(
                            ThemeUtility.getThemeEnumByID(
                                Config.getValue('theme_id'))),
                        setWidgetState: _setState,
                      ),
                      Divider(),
                      Text(
                        I18n.format("settings.appearance.window.size.title"),
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
                              controller: gameWidthController,
                              decoration: InputDecoration(
                                hintText: "854",
                                enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: validWidth, width: 3.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: validWidth, width: 2.0),
                                ),
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                              ),
                              onChanged: (value) async {
                                if (int.tryParse(value) == null) {
                                  validWidth = Colors.red;
                                } else {
                                  Config.change("game_width", int.parse(value));
                                  validWidth = primaryColor;
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
                              controller: gameHeightController,
                              decoration: InputDecoration(
                                hintText: "480",
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: validHeight, width: 3.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: validHeight, width: 2.0),
                                ),
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                              ),
                              onChanged: (value) async {
                                if (int.tryParse(value) == null) {
                                  validHeight = Colors.red;
                                } else {
                                  Config.change(
                                      "game_height", int.parse(value));
                                  validHeight = primaryColor;
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
                      SelectableText(RPMPath.currentDataHome.absolute.path,
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
                    value: checkAssets,
                    onChanged: (value) {
                      _setState(() {
                        checkAssets = !checkAssets;
                        Config.change("check_assets", checkAssets);
                      });
                    },
                    title: I18nText("settings.advanced.assets.check",
                        style: title_, textAlign: TextAlign.center),
                  ),
                  Divider(),
                  SwitchListTile(
                    value: showLog,
                    onChanged: (value) {
                      _setState(() {
                        showLog = !showLog;
                        Config.change("show_log", showLog);
                      });
                    },
                    title: Text("是否啟用控制台輸出遊戲日誌",
                        style: title_, textAlign: TextAlign.center),
                  ),
                  Divider(),
                  SwitchListTile(
                    value: autoDependencies,
                    onChanged: (value) {
                      _setState(() {
                        autoDependencies = !autoDependencies;
                        Config.change("auto_dependencies", autoDependencies);
                      });
                    },
                    title: Text("是否自動下載前置模組",
                        style: title_, textAlign: TextAlign.center),
                  ),
                  Divider(),
                  SwitchListTile(
                    value: autoFullScreen,
                    onChanged: (value) {
                      _setState(() {
                        autoFullScreen = !autoFullScreen;
                        Config.change("auto_full_screen", autoFullScreen);
                      });
                    },
                    title: Text("啟動 RPMLauncher 時是否自動將視窗最大化",
                        style: title_, textAlign: TextAlign.center),
                  ),
                  Divider(),
                  SwitchListTile(
                    value: validateAccount,
                    onChanged: (value) {
                      _setState(() {
                        validateAccount = !validateAccount;
                        Config.change("validate_account", validateAccount);
                      });
                    },
                    title: Text("啟動遊戲時是否檢查帳號憑證過期",
                        style: title_, textAlign: TextAlign.center),
                  ),
                  Divider(),
                  ListTile(
                    title: Text("RPMLauncher 更新通道",
                        style: title_, textAlign: TextAlign.center),
                    trailing: StatefulBuilder(builder: (context, _setState) {
                      return DropdownButton(
                          value: updateChannel,
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
                          onChanged: (dynamic channel) async {
                            _setState(() {
                              updateChannel = channel;
                              Config.change('update_channel',
                                  Updater.toStringFromVersionType(channel));
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
                      Text(I18n.format("settings.advanced.max.log"),
                          style: title_, textAlign: TextAlign.center),
                      SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: TextField(
                          textAlign: TextAlign.center,
                          controller: maxLogLengthController,
                          decoration: InputDecoration(
                            hintText: "500",
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: validLogLength, width: 3.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: validLogLength, width: 2.0),
                            ),
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                          onChanged: (value) async {
                            if (int.tryParse(value) == null) {
                              validLogLength = Colors.red;
                            } else {
                              Config.change("max_log_length", int.parse(value));
                              validLogLength = primaryColor;
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
                title: I18n.format("settings.java.title"),
                icon: Icon(
                  Icons.code_outlined,
                ),
              ),
              ViewOption(
                title: I18n.format("settings.appearance.title"),
                icon: Icon(
                  Icons.web_asset_outlined,
                ),
              ),
              ViewOption(
                title: I18n.format("settings.advanced.title"),
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
  _SettingScreenState createState() => _SettingScreenState();
}
