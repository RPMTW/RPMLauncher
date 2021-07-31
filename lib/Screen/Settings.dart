import 'dart:io' as io;

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

import '../main.dart';

class SettingScreen_ extends State<SettingScreen> {
  bool AutoJava = true;
  String LanguageNamesValue = i18n().LanguageNames[
  i18n().LanguageCodes.indexOf(Config().GetValue("lang_code"))];

  @override
  void initState() {
    i18n();
    JavaController.text = Config().GetValue("java_path");
    AutoJava = Config().GetValue("auto_java");
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

  @override
  var title_ = TextStyle(
    fontSize: 25.0,
    color: Colors.lightBlue,
  );
  var title2_ = TextStyle(
    fontSize: 18.0,
    color: Colors.red,
  );
  var JavaController = TextEditingController();
  var MaxRamController = TextEditingController();
  Color valid_java_bin = Colors.white;
  Color ValidRam = Colors.white;

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("全域設定"),
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
      body: Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          child: ListView(
            children: [
              ListTile(
                title: Text(
                  "Java 選項",
                  textAlign: TextAlign.center,
                  style: title_,
                ),
              ),
              ListTile(
                  title: Row(children: [
                    Expanded(
                        child: TextField(
                          textAlign: TextAlign.center,
                          controller: JavaController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: "Java 路徑",
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: valid_java_bin,
                                  width: 5.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: valid_java_bin,
                                  width: 3.0),
                            ),
                          ),
                          onChanged: (value) async {
                            bool exists_ = await io.File(value).exists();
                            if (value
                                .split("/")
                                .reversed
                                .first == "java" && exists_ ||
                                value
                                    .split("/")
                                    .reversed
                                    .first == "javaw" && exists_) {
                              valid_java_bin = Colors.blue;
                              Config().Change("java_path", value);
                            } else {
                              valid_java_bin = Colors.red;
                            }
                            setState(() {});
                          },
                        )),
                    TextButton(
                        onPressed: () {
                          openSelect(context);
                        },
                        child: Text("選擇 Java 路徑")),
                  ])),
             Column(children: [
                    Text("是否啟用自動下載 Java", style: title2_),
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
                title: Text(
                  "Java 最大記憶體 (MB)",
                  style: title2_,
                  textAlign: TextAlign.center,
                ),
              ),
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
              ListTile(
                title: Text(
                  "外觀設定",
                  textAlign: TextAlign.center,
                  style: title_,
                ),
              ),
              Center(
                  child: Column(
                    children: <Widget>[
                      Text(
                        "啟動器語言",
                        style: title2_,
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
                                i18n().LanguageCodes[i18n()
                                    .LanguageNames
                                    .indexOf(LanguageNamesValue)]);
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
                        "啟動器外觀顏色",
                        style: title2_,
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
          )),
    );
  }
}

String ThemeValue = '黑暗模式';

class SettingScreen extends StatefulWidget {
  @override
  SettingScreen_ createState() => SettingScreen_();
}
