import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';

import '../main.dart';

var java_path;

class SettingScreen_ extends State<SettingScreen> {
  void openSelect(BuildContext context) async {

    final file = await FileSelectorPlatform.instance.openFile();
    if (file == null) {
      return;
    }
    if (file.name == "java" || file.name == "javaw") {
      java_path = file.path;
      controller_java.text = java_path;
      java_path = controller_java.text;
      print(java_path);
    }else{
      showDialog(context: context, builder: (context){
        return AlertDialog(title: const Text("Not Java"),content: Text("This is not a java or javaw"),actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],);
      });
    }
  }

  @override
  var title_ = TextStyle(
    fontSize: 20.0,
  );
  var controller_java = TextEditingController();
   Color valid_java_bin=Colors.white;

  @override
  void initState() {
    super.initState();
    controller_java.addListener(() {
      if (controller_java.text.split("/").reversed.first == "java" ||
          controller_java.text.split("/").reversed.first == "javaw") {
        valid_java_bin = Colors.blue;
      } else {
        valid_java_bin = Colors.red;
      }
      setState(() {

      });
    });
  }

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
                  title: Row(children: [
                Expanded(
                    child: TextField(
                  controller: controller_java,
                  decoration: InputDecoration(
                      hintText: "Java path",
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: valid_java_bin, width: 5.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: valid_java_bin, width: 3.0),
                    ),),
                )),
                TextButton(
                    onPressed: () {
                      openSelect(context);

                    },
                    child: Text("Choose java")),
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
