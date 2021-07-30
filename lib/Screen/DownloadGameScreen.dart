import 'package:flutter/material.dart';

import '../main.dart';

class DownloadGameScreen_ extends State<DownloadGameScreen> {
  bool _obscureText = true;

  @override
  var title_ = TextStyle(
    fontSize: 20.0,
  );

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("下載遊戲中"),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: '取消下載',
          onPressed: () {
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new LauncherHome()),
            );
          },
        ),
      ),
      body: Text("")
    );
  }
}

class DownloadGameScreen extends StatefulWidget {
  @override
  DownloadGameScreen_ createState() => DownloadGameScreen_();
}
