import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../main.dart';

Future<String> VanillaVersion() async {
  final url = Uri.parse(
      'https://launchermeta.mojang.com/mc/game/version_manifest_v2.json');
  Response response = await get(url);
  return response.body;
}

// ignore: must_be_immutable, camel_case_types
class VersionSelection_ extends State<VersionSelection> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  static List<Widget> _widgetOptions = <Widget>[
    FutureBuilder(
        future: VanillaVersion(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Text(jsonDecode(snapshot.data.toString()).latest.toString());
          } else {
            return Center(child: CircularProgressIndicator());
          }
        }),
    Text(
      '鍛造',
      style: optionStyle,
      textAlign: TextAlign.center,
    ),
    Text(
      '織物',
      style: optionStyle,
      textAlign: TextAlign.center,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("請選擇安裝檔的類型"),
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
      body: Row(
        children: <Widget>[
          _widgetOptions.elementAt(_selectedIndex),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Container(
                  width: 30,
                  height: 30,
                  child: Image.asset("images/Vanilla.ico")),
              label: '原版',
              tooltip: '原版'),
          BottomNavigationBarItem(
              icon: Container(
                  width: 30,
                  height: 30,
                  child: Image.asset("images/Forge.jpg")),
              label: 'Forge',
              tooltip: 'Forge'),
          BottomNavigationBarItem(
              icon: Container(
                  width: 30,
                  height: 30,
                  child: Image.asset("images/Fabric.png")),
              label: 'Fabric',
              tooltip: 'Fabric'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        onTap: _onItemTapped,
      ),
    );
  }
}

class VersionSelection extends StatefulWidget {
  @override
  VersionSelection_ createState() => VersionSelection_();
}
