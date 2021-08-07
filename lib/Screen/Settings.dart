import 'dart:io' as io;

import 'package:RPMLauncher/Utility/Config.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:RPMLauncher/Utility/utility.dart';
import 'package:flutter/material.dart';
import 'package:split_view/split_view.dart';
import 'package:system_info/system_info.dart';

import '../main.dart';

class SettingScreen_ extends State<SettingScreen> {
  bool AutoJava = true;
  bool CheckAssets = true;
  bool ShowLog = false;
  bool AutoDependencies = true;
  String LanguageNamesValue = i18n.LanguageNames[
      i18n.LanguageCodes.indexOf(Config().GetValue("lang_code"))];
  String JavaVersion = "8";
  List<String> JavaVersions = ["8", "16"];

  int selectedIndex = 0;
  late List<Widget> WidgetList;
  final RamMB = (SysInfo.getTotalPhysicalMemory()) / 1024 / 1024;

  @override
  void initState() {
    JavaController.text = Config().GetValue("java_path_${JavaVersion}");
    AutoJava = Config().GetValue("auto_java");
    CheckAssets = Config().GetValue("check_assets");
    ShowLog = Config().GetValue("show_log");
    AutoDependencies = Config().GetValue("auto_dependencies");
    MaxRamController.text = Config().GetValue("java_max_ram").toString();
    GameWidthController.text = Config().GetValue("game_width").toString();
    GameHeightController.text = Config().GetValue("game_height").toString();
    MaxLogLengthController.text =
        Config().GetValue("max_log_length").toString();
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
  var JavaController = TextEditingController();
  var MaxRamController = TextEditingController();

  var GameWidthController = TextEditingController();
  var GameHeightController = TextEditingController();

  var MaxLogLengthController = TextEditingController();

  Color validJavaBin = Colors.white;
  Color ValidRam = Colors.white;
  Color ValidWidth = Colors.white;
  Color ValidHeight = Colors.white;
  Color ValidLogLength = Colors.white;

  Widget build(BuildContext context) {
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
              Text("    ${i18n.Format("java.version")}: ", style: title2_),
              DropdownButton<String>(
                value: JavaVersion,
                style: const TextStyle(color: Colors.white),
                onChanged: (String? newValue) {
                  setState(() {
                    JavaVersion = newValue!;
                    JavaController.text =
                        Config().GetValue("java_path_${JavaVersion}");
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
                    borderSide: BorderSide(color: validJavaBin, width: 5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: validJavaBin, width: 3.0),
                  ),
                ),
                onChanged: (value) async {
                  bool exists_ = await io.File(value).exists();
                  if (value.split("/").reversed.first == "java" && exists_ ||
                      value.split("/").reversed.first == "javaw" && exists_) {
                    validJavaBin = Colors.blue;
                    Config().Change("java_path_${JavaVersion}", value);
                  } else {
                    validJavaBin = Colors.red;
                  }
                  setState(() {});
                },
              )),
              SizedBox(
                width: 12,
              ),
              ElevatedButton(
                  onPressed: () {
                    utility.OpenJavaSelectScreen(context, JavaVersion).then(
                        (value) => {
                              JavaController.text =
                                  Config().GetValue("java_path_${JavaVersion}")
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
                    Config().Change("auto_java", AutoJava);
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
                  Config().Change("java_max_ram", int.parse(value));
                  ValidRam = Colors.white;
                }
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
              Text(
                i18n.Format("settings.appearance.language.title"),
                style: title_,
              ),
              DropdownButton<String>(
                value: LanguageNamesValue,
                style: const TextStyle(color: Colors.white),
                onChanged: (String? newValue) {
                  setState(() {
                    LanguageNamesValue = newValue!;
                    Config().Change(
                        "lang_code",
                        i18n.LanguageCodes[
                            i18n.LanguageNames.indexOf(LanguageNamesValue)]);
                  });
                },
                items: i18n.LanguageNames.map<DropdownMenuItem<String>>(
                    (String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              Text(
                "啟動器主題 (WIP)",
                style: title_,
              ),
              Center(
                child: DropdownButton<String>(
                  value: ThemeValue,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (String? newValue) {
                    setState(() {
                      ThemeValue = newValue!;
                    });
                  },
                  items: <String>['黑暗模式', '淺色模式']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
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
                        hintText: "1920",
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
                          Config().Change("game_width", int.parse(value));
                          ValidWidth = Colors.white;
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
                        hintText: "1080",
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
                          Config().Change("game_height", int.parse(value));
                          ValidHeight = Colors.white;
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
          Text("如果您不了解此頁面的用途什麼請不要調整此頁面的選項",style: TextStyle(color: Colors.red,fontSize: 30),textAlign: TextAlign.center),
          Text(i18n.Format("settings.advanced.assets.check"),
              style: title_, textAlign: TextAlign.center),
          Switch(
              value: CheckAssets,
              onChanged: (value) {
                setState(() {
                  CheckAssets = !CheckAssets;
                  Config().Change("check_assets", CheckAssets);
                });
              }),
          Text("是否啟用控制台輸出遊戲日誌", style: title_, textAlign: TextAlign.center),
          Switch(
              value: ShowLog,
              onChanged: (value) {
                setState(() {
                  ShowLog = !ShowLog;
                  Config().Change("show_log", ShowLog);
                });
              }),
          Text("是否自動下載前置模組", style: title_, textAlign: TextAlign.center),
          Switch(
              value: AutoDependencies,
              onChanged: (value) {
                setState(() {
                  AutoDependencies = !AutoDependencies;
                  Config().Change("auto_dependencies", AutoDependencies);
                });
              }),
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
                      Config().Change("max_log_length", int.parse(value));
                      ValidLogLength = Colors.white;
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
         Text("如果您不了解此頁面的用途什麼請不要調整此頁面的選項",style: TextStyle(color: Colors.red,fontSize: 30),textAlign: TextAlign.center)
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

String ThemeValue = '黑暗模式';

class SettingScreen extends StatefulWidget {
  @override
  SettingScreen_ createState() => SettingScreen_();
}
