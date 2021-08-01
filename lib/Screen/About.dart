import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

import '../main.dart';

var java_path;

class AboutScreen_ extends State<AboutScreen> {
  @override
  var title_ = TextStyle(
    fontSize: 20.0,
  );

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("關於 RPMLauncher"),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: i18n().Format("gui.back"),
          onPressed: () {
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new LauncherHome()),
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
              Transform.scale(
                  child: TextButton(
                    onPressed: () {
                      showLicensePage(
                        context: context,
                      );
                    },
                    child: Text('顯示開源函式庫授權'),
                  ),
                  scale: 2),
              Center(
                child: Text(
                    "\nCopyright © RPMLauncher  2021-2021  All Right Reserved"),
              )
            ],
          )),
    );
  }
}

class AboutScreen extends StatefulWidget {
  @override
  AboutScreen_ createState() => AboutScreen_();
}
