import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:split_view/split_view.dart';

import '../main.dart';
import '../path.dart';
import 'DownloadGameScreen.dart';

var httpClient = new HttpClient();

Future VanillaVersion() async {
  final url = Uri.parse(
      'https://launchermeta.mojang.com/mc/game/version_manifest_v2.json');
  Response response = await get(url);
  Map<String, dynamic> body = jsonDecode(response.body);
  return body;
}

class VersionSelection_ extends State<VersionSelection> {
  int _selectedIndex = 0;
  late Future vanilla_choose;
  bool ShowRelease = true;
  bool ShowSnapshot = false;
  bool ShowAlpha = false;
  bool ShowBeta = false;
  int choose_index = 0;
  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
  late List<Widget> _widgetOptions;
  static Directory LauncherFolder = dataHome;
  Directory InstanceDir =
      Directory(join(LauncherFolder.absolute.path, "instances"));

  void initState() {
    super.initState();
    vanilla_choose = VanillaVersion();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  var name_controller = TextEditingController();
  late var border_colour = Colors.lightBlue;

  @override
  Widget build(BuildContext context) {
    _widgetOptions = <Widget>[
      FutureBuilder(
          future: vanilla_choose,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return ListView.builder(
                  itemCount: snapshot.data["versions"].length,
                  itemBuilder: (context, index) {
                    var list_tile = ListTile(
                      title: Text(
                          snapshot.data["versions"][index]["id"].toString()),
                      tileColor: choose_index == index
                          ? Colors.white30
                          : Colors.white10,
                      onTap: () {
                        choose_index = index;
                        name_controller.text =
                            snapshot.data["versions"][index]["id"].toString();
                        setState(() {});
                        if (File(join(InstanceDir.absolute.path,
                                name_controller.text, "instance.cfg"))
                            .existsSync()) {
                          border_colour = Colors.red;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DownloadGameScreen(
                                  border_colour,
                                  name_controller,
                                  InstanceDir,
                                  snapshot.data["versions"][choose_index])),
                        );
                      },
                    );
                    var type = snapshot.data["versions"][index]["type"];
                    switch (type) {
                      case "release":
                        if (ShowRelease) return list_tile;
                        break;
                      case "snapshot":
                        if (ShowSnapshot) return list_tile;
                        break;
                      case "old_beta":
                        if (ShowBeta) return list_tile;
                        break;
                      case "old_alpha":
                        if (ShowAlpha) return list_tile;
                        break;
                      default:
                        break;
                    }
                    return Container();
                  });
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
      Text(
        '壓縮檔',
        style: optionStyle,
        textAlign: TextAlign.center,
      ),
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
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("請選擇安裝檔的類型"),
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
      body: SplitView(
        view1: _widgetOptions.elementAt(_selectedIndex),
        view2: Column(
          children: [
            Text(i18n().Format("version.list.filter")),
            ListTile(
              leading: Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    ShowRelease = value!;
                    //vanilla_choose = VanillaVersion();
                  });
                },
                value: ShowRelease,
              ),
              title: Text(i18n().Format("version.list.show.release")),
            ),
            ListTile(
              leading: Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    ShowSnapshot = value!;
                    //vanilla_choose = VanillaVersion();
                  });
                },
                value: ShowSnapshot,
              ),
              title: Text(i18n().Format("version.list.show.snapshot")),
            ),
            ListTile(
              leading: Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    ShowBeta = value!;
                    //vanilla_choose = VanillaVersion();
                  });
                },
                value: ShowBeta,
              ),
              title: Text(i18n().Format("version.list.show.beta")),
            ),
            ListTile(
              leading: Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    ShowAlpha = value!;
                    //vanilla_choose = VanillaVersion();
                  });
                },
                value: ShowAlpha,
              ),
              title: Text(i18n().Format("version.list.show.alpha")),
            ),
          ],
        ),
        gripSize: 0,
        initialWeight: 0.83,
        viewMode: SplitViewMode.Horizontal,
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
                  child: Icon(Icons.folder_open_outlined)),
              label: '壓縮檔',
              tooltip: '壓縮檔'),
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
