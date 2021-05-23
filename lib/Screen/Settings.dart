import 'dart:convert';
import 'dart:io' as io;

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:xdg_directories/xdg_directories.dart';

import '../main.dart';

var java_path;

class SettingScreen_ extends State<SettingScreen> {
  late io.Directory ConfigFolder;
  late io.File ConfigFile;
  late Map config;
  bool AutoJava = true;

  @override
  void initState() {
    ConfigFolder = configHome;
    ConfigFile =
        io.File(join(ConfigFolder.absolute.path, "RPMLauncher", "config.json"));
    config = json.decode(ConfigFile.readAsStringSync());
    if (config.containsKey("java_path")) {
      controller_java.text = config["java_path"];
    }
    if (config.containsKey("auto_java")) {
      AutoJava = config["auto_java"];
    }
    super.initState();
    controller_java.addListener(() async {
      bool exists_ = await io.File(controller_java.text).exists();
      if (controller_java.text.split("/").reversed.first == "java" && exists_ ||
          controller_java.text.split("/").reversed.first == "javaw" &&
              exists_) {
        valid_java_bin = Colors.blue;
        config["java_path"] = controller_java.text;
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
    if (file.name == "java" || file.name == "javaw") {
      java_path = file.path;
      controller_java.text = java_path;
      java_path = controller_java.text;
      config["java_path"] = java_path;
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("尚未偵測到 Java"),
              content: Text("這個檔案不是 java 或 javaw。"),
              actions: <Widget>[
                TextButton(
                  child: const Text('確認'),
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
    fontSize: 20.0,
  );
  var controller_java = TextEditingController();
  Color valid_java_bin = Colors.white;

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("設定選單"),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () {
            ConfigFile.writeAsStringSync(json.encode(config));
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new MyApp()),
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
                    child: Text("選擇 Java")),
              ])),
              ListTile(),
              ListTile(
                  title: Row(children: [
                Text("是否啟用自動下載 Java"),
                Switch(
                    value: AutoJava,
                    onChanged: (value) {
                      setState(() {
                        AutoJava = !AutoJava;
                        config["auto_java"] = !AutoJava;
                      });
                    })
              ]))
            ],
          )),
    );
  }
}

class SettingScreen extends StatefulWidget {
  @override
  SettingScreen_ createState() => SettingScreen_();
}
