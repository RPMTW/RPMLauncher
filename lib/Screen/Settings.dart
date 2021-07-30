import 'dart:io' as io;

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/MCLauncher/Arguments.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

import '../main.dart';

class SettingScreen_ extends State<SettingScreen> {
  bool AutoJava = true;
  String LanguageNamesValue = i18n().LanguageNames[i18n().LanguageCodes.indexOf(Config().GetValue("lang_code"))];

  @override
  void initState() {
    i18n();
    controller_java.text = Config().GetValue("java_path");
    AutoJava = Config().GetValue("auto_java");
    super.initState();
    controller_java.addListener(() async {
      bool exists_ = await io.File(controller_java.text).exists();
      if (controller_java.text.split("/").reversed.first == "java" && exists_ ||
          controller_java.text.split("/").reversed.first == "javaw" &&
              exists_) {
        valid_java_bin = Colors.blue;
        Config().Change("java_path", controller_java.text);
      } else {
        valid_java_bin = Colors.red;
      }
      setState(() {});
    });
  }

  void openSelect(BuildContext context) async {
    final file = await FileSelectorPlatform.instance.openFile();
    if (file == null) {
      return;
    }
    if (file.name.startsWith("java") ||
        file.name.startsWith("java") == "javaw") {
      controller_java.text = file.path;
      Config().Change("java_path", controller_java.text);
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
  var controller_java = TextEditingController();
  Color valid_java_bin = Colors.white;

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
                  controller: controller_java,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: "Java 路徑",
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: valid_java_bin, width: 5.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: valid_java_bin, width: 3.0),
                    ),
                  ),
                )),
                TextButton(
                    onPressed: () {
                      openSelect(context);
                    },
                    child: Text("選擇 Java 路徑")),
              ])),
              Center(
                  child: Column(children: [
                Text("是否啟用自動下載 Java", style: title2_),
                Switch(
                    value: AutoJava,
                    onChanged: (value) {
                      setState(() {
                        AutoJava = !AutoJava;
                        Config().Change("auto_java", AutoJava);
                      });
                    })
              ])),
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
