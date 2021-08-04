import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

import '../main.dart';

var java_path;

class AboutScreen_ extends State<AboutScreen> {
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(i18n().Format("homepage.about")),
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
      body: ListView(
        children: [
          SizedBox(
            height: 12,
          ),
          Transform.scale(
            child: IconButton(
              icon: Icon(Icons.book_outlined),
              onPressed: () {
                showLicensePage(
                  context: context,
                );
              },
            ),
            scale: 2,
          ),
          SizedBox(
            height: 12,
          ),
          Text(i18n().Format("about.license.show"),
              style: new TextStyle(fontSize: 20, color: Colors.lightBlue),
              textAlign: TextAlign.center)
        ],
      ),
      persistentFooterButtons: [
        Center(
          child: Text("Copyright © RPMLauncher And RPMTW Team 2021-2021  All Right Reserved."),
        )
      ],
    );
  }
}

class AboutScreen extends StatefulWidget {
  @override
  AboutScreen_ createState() => AboutScreen_();
}
