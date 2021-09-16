import 'dart:io' as io;

import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Model/JvmArgs.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:split_view/split_view.dart';
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

  String JavaVersion = "8";
  List<String> JavaVersions = ["8", "16"];
  int selectedIndex = 0;
  late List<Widget> WidgetList;
  final RamMB = (SysInfo.getTotalPhysicalMemory()) / 1024 / 1024;

  @override
  void initState() {
    JavaController.text = Config.GetValue("java_path_${JavaVersion}");
    AutoJava = Config.GetValue("auto_java");
    CheckAssets = Config.GetValue("check_assets");
    ShowLog = Config.GetValue("show_log");
    AutoDependencies = Config.GetValue("auto_dependencies");
    MaxRamController.text = Config.GetValue("java_max_ram").toString();
    GameWidthController.text = Config.GetValue("game_width").toString();
    GameHeightController.text = Config.GetValue("game_height").toString();
    MaxLogLengthController.text = Config.GetValue("max_log_length").toString();
    JvmArgsController.text =
        JvmArgs.fromList(Config.GetValue("java_jvm_args")).args;

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
    ThemeUtility.UpdateTheme(context);
    WidgetList = [
      ListView(
        children: [
          Text(
            i18n.Format("settings.java.path"),
            style: title_,
            textAlign: TextAlign.center,
          ),
          Row(
            children: [
              Text("    ${i18n.Format("java.version")}: ", style: title_),
              DropdownButton<String>(
                value: JavaVersion,
                onChanged: (String? newValue) {
                  setState(() {
                    JavaVersion = newValue!;
                    JavaController.text =
                        Config.GetValue("java_path_${JavaVersion}");
                  });
                },
                items:
                    JavaVersions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value,
                        style: new TextStyle(fontSize: 20),
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
                  hintText: i18n.Format("settings.java.path"),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: PrimaryColor, width: 5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: PrimaryColor, width: 3.0),
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
                        Config.Change("java_path_$JavaVersion", value[1]);
                        JavaController.text =
                            Config.GetValue("java_path_${JavaVersion}");
                      }
                    });
                  },
                  child: Text(
                    i18n.Format("settings.java.path.select"),
                    style: new TextStyle(fontSize: 18),
                  )),
              SizedBox(
                width: 12,
              ),
            ],
          ),
          Column(children: [
            Text(i18n.Format("settings.java.auto"), style: title_),
            Switch(
                value: AutoJava,
                onChanged: (value) {
                  setState(() {
                    AutoJava = !AutoJava;
                    Config.Change("auto_java", AutoJava);
                  });
                })
          ]),
          ListTile(
              title: Column(children: [
            Text(
              i18n.Format("settings.java.ram.max"),
              style: title_,
              textAlign: TextAlign.center,
            ),
            Text(
                "${i18n.Format("settings.java.ram.physical")} ${RamMB.toStringAsFixed(0)} MB")
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
                if (int.tryParse(value) == null || int.parse(value) > RamMB) {
                  ValidRam = Colors.red;
                } else {
                  Config.Change("java_max_ram", int.parse(value));
                  ValidRam = PrimaryColor;
                }
                setState(() {});
              },
            ),
          ),
          Text(
            i18n.Format('settings.java.jvm.args'),
            style: title_,
            textAlign: TextAlign.center,
          ),
          ListTile(
            title: TextField(
              textAlign: TextAlign.center,
              controller: JvmArgsController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: PrimaryColor, width: 5.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: PrimaryColor, width: 3.0),
                ),
              ),
              onChanged: (value) async {
                Config.Change('java_jvm_args', JvmArgs(args: value).toList());
                setState(() {});
              },
            ),
          ),
        ],
      ),
      ListView(
        children: [
          Center(
              child: Column(
            children: <Widget>[
              i18n.SelectorWidget(),
              Text(
                i18n.Format("settings.appearance.theme"),
                style: title_,
              ),
              DropdownButton(
                  value: ThemeValue,
                  items: [
                    DropdownMenuItem(
                      value: ThemeUtility.Light,
                      child:
                          Text(ThemeUtility.toI18nString(ThemeUtility.Light)),
                    ),
                    DropdownMenuItem(
                      value: ThemeUtility.Dark,
                      child: Text(ThemeUtility.toI18nString(ThemeUtility.Dark)),
                    ),
                  ],
                  onChanged: (dynamic themeId) async {
                    await DynamicTheme.of(context)!.setTheme(themeId);
                    setState(() {
                      ThemeValue = themeId;
                      Config.Change('theme_id', themeId);
                    });
                  }),
              Text(
                i18n.Format("settings.appearance.window.size.title"),
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
                          borderSide: BorderSide(color: ValidWidth, width: 3.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: ValidWidth, width: 2.0),
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
                          Config.Change("game_width", int.parse(value));
                          ValidWidth = PrimaryColor;
                        }
                        setState(() {});
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
                          borderSide:
                              BorderSide(color: ValidHeight, width: 3.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: ValidHeight, width: 2.0),
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
                          Config.Change("game_height", int.parse(value));
                          ValidHeight = PrimaryColor;
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(
                    width: 12,
                  ),
                ],
              )
            ],
          )),
        ],
      ),
      ListView(
        children: [
          Text("如果您不了解此頁面的用途，請不要調整此頁面的選項",
              style: TextStyle(color: Colors.red, fontSize: 30),
              textAlign: TextAlign.center),
          Text(i18n.Format("settings.advanced.assets.check"),
              style: title_, textAlign: TextAlign.center),
          Switch(
              value: CheckAssets,
              onChanged: (value) {
                setState(() {
                  CheckAssets = !CheckAssets;
                  Config.Change("check_assets", CheckAssets);
                });
              }),
          Text("是否啟用控制台輸出遊戲日誌", style: title_, textAlign: TextAlign.center),
          Switch(
              value: ShowLog,
              onChanged: (value) {
                setState(() {
                  ShowLog = !ShowLog;
                  Config.Change("show_log", ShowLog);
                });
              }),
          Text("是否自動下載前置模組", style: title_, textAlign: TextAlign.center),
          Switch(
              value: AutoDependencies,
              onChanged: (value) {
                setState(() {
                  AutoDependencies = !AutoDependencies;
                  Config.Change("auto_dependencies", AutoDependencies);
                });
              }),
          Text("RPMLauncher 更新通道", style: title_, textAlign: TextAlign.center),
          Center(
            child: DropdownButton(
                value: UpdateChannel,
                items: [
                  DropdownMenuItem(
                    value: VersionTypes.stable,
                    child: Text(Updater.toI18nString(VersionTypes.stable)),
                  ),
                  DropdownMenuItem(
                    value: VersionTypes.dev,
                    child: Text(Updater.toI18nString(VersionTypes.dev)),
                  ),
                ],
                onChanged: (dynamic Channel) async {
                  setState(() {
                    UpdateChannel = Channel;
                    Config.Change(
                        'update_channel', Updater.toStringFromVersionType(Channel));
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
              Text(i18n.Format("settings.advanced.max.log"),
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
                      borderSide: BorderSide(color: ValidLogLength, width: 3.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: ValidLogLength, width: 2.0),
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
                      Config.Change("max_log_length", int.parse(value));
                      ValidLogLength = PrimaryColor;
                    }
                    setState(() {});
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
                    GameRepository.DataHomeRootDir.deleteSync(recursive: true);
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
                    GameRepository.DataHomeRootDir.deleteSync(recursive: true);
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
      )
    ];
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(i18n.Format("settings.title")),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: i18n.Format("gui.back"),
          onPressed: () {
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => LauncherHome()),
            );
          },
        ),
      ),
      body: SplitView(
          view1: ListView(
            children: [
              ListTile(
                title: Text(
                  i18n.Format("settings.java.title"),
                ),
                leading: Icon(
                  Icons.code_outlined,
                ),
                onTap: () {
                  selectedIndex = 0;
                  setState(() {});
                },
                tileColor: selectedIndex == 0
                    ? Colors.white12
                    : Theme.of(context).scaffoldBackgroundColor,
              ),
              ListTile(
                title: Text(i18n.Format("settings.appearance.title")),
                leading: Icon(
                  Icons.web_asset_outlined,
                ),
                onTap: () {
                  selectedIndex = 1;
                  setState(() {});
                },
                tileColor: selectedIndex == 1
                    ? Colors.white12
                    : Theme.of(context).scaffoldBackgroundColor,
              ),
              ListTile(
                title: Text(i18n.Format("settings.advanced.title")),
                leading: Icon(
                  Icons.settings,
                ),
                onTap: () {
                  selectedIndex = 2;
                  setState(() {});
                },
                tileColor: selectedIndex == 2
                    ? Colors.white12
                    : Theme.of(context).scaffoldBackgroundColor,
              ),
              ListTile(
                title: Text("除錯選項"),
                leading: Icon(
                  Icons.bug_report,
                ),
                onTap: () {
                  selectedIndex = 3;
                  setState(() {});
                },
                tileColor: selectedIndex == 3
                    ? Colors.white12
                    : Theme.of(context).scaffoldBackgroundColor,
              ),
            ],
          ),
          view2: WidgetList[selectedIndex],
          gripSize: 3,
          initialWeight: 0.2,
          viewMode: SplitViewMode.Horizontal),
    );
  }
}

int ThemeValue = Config.GetValue('theme_id');
VersionTypes UpdateChannel =
    Updater.getVersionTypeFromString(Config.GetValue('update_channel'));

class SettingScreen extends StatefulWidget {
  @override
  SettingScreen_ createState() => SettingScreen_();
}
