import 'package:flutter/material.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

import '../main.dart';

var java_path;
class SettingScreen_ extends State<SettingScreen> {
  void openSelect() async {
    final file = await FileSelectorPlatform.instance
        .openFile();
    if (file == null) {
      return;
    }
    if (file.name=="java"||file.name=="javaw") {
      java_path = file.path;
    }
  }
  @override
  var title_ = TextStyle(
    fontSize: 20.0,
  );
  var controller_java=TextEditingController();
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("設定選單"),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () {
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
                title:Row(children: [Expanded(child: TextField(controller: controller_java,)), TextButton(
                    onPressed: () {
                      openSelect();
                      controller_java.text=java_path;
                      java_path=controller_java.text;
                      print(java_path);
                    },
                    child: Text("Choose java")),])
              )
            ],
          )),
    );
  }
}

class SettingScreen extends StatefulWidget {
  @override
  SettingScreen_ createState() => SettingScreen_();
}
