import 'dart:io' as io;

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:split_view/split_view.dart';
import 'package:system_info/system_info.dart';

import '../main.dart';

class SettingScreen_ extends State<SettingScreen> {
  bool AutoJava = true;
  bool CheckAssets = true;
  String LanguageNamesValue = i18n().LanguageNames[
      i18n().LanguageCodes.indexOf(Config().GetValue("lang_code"))];
  int selectedIndex = 0;
  late List<Widget> WidgetList;

  @override
  void initState() {
    i18n();
    JavaController.text = Config().GetValue("java_path");
    AutoJava = Config().GetValue("auto_java");
    CheckAssets = Config().GetValue("check_assets");
    MaxRamController.text = Config().GetValue("java_max_ram").toString();
    super.initState();
  }

  void openSelect(BuildContext context) async {
    final file = await FileSelectorPlatform.instance.openFile();
    if (file == null) {
      return;
    }
    if (file.name.startsWith("java") ||
        file.name.startsWith("java") == "javaw") {
      JavaController.text = file.path;
      Config().Change("java_path", JavaController.text);
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("尚未偵測到 Java"),
              content: Text("這個檔案不是 java 或 javaw。"),
              actions: <Widget>[
                TextButton(
                  child: Text(i18n().Format("gui.confirm")),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
    }
  }

  var title_ = TextStyle(
    fontSize: 20.0,
    color: Colors.red,
  );
  var JavaController = TextEditingController();
  var MaxRamController = TextEditingController();
  Color valid_java_bin = Colors.white;
  Color ValidRam = Colors.white;

  Widget build(BuildContext context) {
    WidgetList = [
      ListView(
        children: [
          Text(
            i18n().Format("settings.java.path"),
            style: title_,
            textAlign: TextAlign.center,
          ),
          Row(
            children: [
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                controller: JavaController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: i18n().Format("settings.java.path"),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: valid_java_bin, width: 5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: valid_java_bin, width: 3.0),
                  ),
                ),
                onChanged: (value) async {
                  bool exists_ = await io.File(value).exists();
                  if (value.split("/").reversed.first == "java" && exists_ ||
                      value.split("/").reversed.first == "javaw" && exists_) {
                    valid_java_bin = Colors.blue;
                    Config().Change("java_path", value);
                  } else {
                    valid_java_bin = Colors.red;
                  }
                  setState(() {});
                },
              )),
              SizedBox(
                width: 12,
              ),
              ElevatedButton(
                  onPressed: () {
                    openSelect(context);
                  },
                  child: Text(
                    i18n().Format("settings.java.path.select"),
                    style: new TextStyle(fontSize: 18),
                  )),
              SizedBox(
                width: 12,
              ),
            ],
          ),
          Column(children: [
            Text(i18n().Format("settings.java.auto"), style: title_),
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
              i18n().Format("settings.java.ram.max"),
              style: title_,
              textAlign: TextAlign.center,
            ),
            Text(
                "${i18n().Format("settings.java.ram.physical")} ${((SysInfo.getTotalPhysicalMemory()) / 1024 / 1024).toStringAsFixed(0)} MB")
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
                if (int.tryParse(value) == null) {
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
                i18n().Format("settings.appearance.language.title"),
                style: title_,
              ),
              DropdownButton<String>(
                value: LanguageNamesValue,
                style: const TextStyle(color: Colors.white),
                underline: Container(
                  height: 0,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    LanguageNamesValue = newValue!;
                    Config().Change(
                        "lang_code",
                        i18n().LanguageCodes[
                            i18n().LanguageNames.indexOf(LanguageNamesValue)]);
                  });
                },
                items: i18n()
                    .LanguageNames
                    .map<DropdownMenuItem<String>>((String value) {
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
                  underline: Container(
                    height: 0,
                  ),
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
            ],
          )),
        ],
      ),
      ListView(
        children: [
          Column(children: [
            Text(i18n().Format("settings.advanced.assets.check"), style: title_),
            Switch(
                value: CheckAssets,
                onChanged: (value) {
                  setState(() {
                    CheckAssets = !CheckAssets;
                    Config().Change("check_assets", CheckAssets);
                  });
                })
          ]),
        ],
      )
    ];
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(i18n().Format("settings.title")),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: i18n().Format("gui.back"),
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
                  i18n().Format("settings.java.title"),
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
                title: Text(i18n().Format("settings.appearance.title")),
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
                title: Text(i18n().Format("settings.advanced.title")),
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
