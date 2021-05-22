import 'package:flutter/material.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

import '../main.dart';

var java_path;
class AccountScreen_ extends State<AccountScreen> {
  @override
  var title_ = TextStyle(
    fontSize: 20.0,
  );
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("管理Minecraft帳號"),
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
                  "Mojang 帳號",
                  textAlign: TextAlign.center,
                  style: title_,
                ),
              ),
              ListTile(
                title: Text(
                  "Microsoft 帳號",
                  textAlign: TextAlign.center,
                  style: title_,
                ),
              ),
            ],
          )),
    );
  }
}

class AccountScreen extends StatefulWidget {
  @override
  AccountScreen_ createState() => AccountScreen_();
}
