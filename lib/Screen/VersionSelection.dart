import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/MCLauncher/APIs.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:split_view/split_view.dart';

import '../main.dart';
import '../path.dart';
import 'DownloadGameScreen.dart';

var httpClient = new HttpClient();

Future VanillaVersion() async {
  final url = Uri.parse("${APis().MojangMetaAPI}/version_manifest_v2.json");
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
  var VersionSearchController = new TextEditingController();

  var ModLoaderNames = [
    i18n().Format("version.list.mod.loader.vanilla"),
    i18n().Format("version.list.mod.loader.fabric"),
    i18n().Format("version.list.mod.loader.forge")
  ];
  var ModLoader = i18n().Format("version.list.mod.loader.vanilla");
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
                    var VersionId = snapshot.data["versions"][index]["id"];
                    bool InputID =
                        VersionId.contains(VersionSearchController.text);
                    switch (type) {
                      case "release":
                        if (ShowRelease && InputID) return list_tile;
                        break;
                      case "snapshot":
                        if (ShowSnapshot && InputID) return list_tile;
                        break;
                      case "old_beta":
                        if (ShowBeta && InputID) return list_tile;
                        break;
                      case "old_alpha":
                        if (ShowAlpha && InputID) return list_tile;
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
                    var VersionId = snapshot.data["versions"][index]["id"];
                    bool InputID =
                        VersionId.contains(VersionSearchController.text);
                    switch (type) {
                      case "release":
                        if (ShowRelease && InputID) return list_tile;
                        break;
                      case "snapshot":
                        if (ShowSnapshot && InputID) return list_tile;
                        break;
                      case "old_beta":
                        if (ShowBeta && InputID) return list_tile;
                        break;
                      case "old_alpha":
                        if (ShowAlpha && InputID) return list_tile;
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
            Text(
              i18n().Format("version.list.mod.loader"),
              style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: ModLoader,
              style: const TextStyle(color: Colors.lightBlue),
              underline: Container(
                height: 0,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  ModLoader = newValue!;
                });
              },
              items:
                  ModLoaderNames.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: new TextStyle(fontSize: 17.5)),
                );
              }).toList(),
            ),
            Text(
              i18n().Format("version.list.filter"),
              style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 45,
              width: 250,
              child: TextField(
                controller: VersionSearchController,
                textAlign: TextAlign.center,
                style: new TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            ListTile(
              leading: Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    ShowRelease = value!;
                  });
                },
                value: ShowRelease,
              ),
              title: Text(
                i18n().Format("version.list.show.release"),
                style: TextStyle(
                  fontSize: 17.5,
                ),
              ),
            ),
            ListTile(
              leading: Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    ShowSnapshot = value!;
                  });
                },
                value: ShowSnapshot,
              ),
              title: Text(
                i18n().Format("version.list.show.snapshot"),
                style: TextStyle(
                  fontSize: 17.5,
                ),
              ),
            ),
            ListTile(
              leading: Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    ShowBeta = value!;
                  });
                },
                value: ShowBeta,
              ),
              title: Text(
                i18n().Format("version.list.show.beta"),
                style: TextStyle(
                  fontSize: 17.5,
                ),
              ),
            ),
            ListTile(
              leading: Checkbox(
                onChanged: (bool? value) {
                  setState(() {
                    ShowAlpha = value!;
                  });
                },
                value: ShowAlpha,
              ),
              title: Text(
                i18n().Format("version.list.show.alpha"),
                style: TextStyle(
                  fontSize: 17.5,
                ),
              ),
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
                  child: Image.asset("images/Minecraft.png")),
              label: 'Minecraft',
              tooltip: ''),
          BottomNavigationBarItem(
              icon: Container(
                  width: 30,
                  height: 30,
                  child: Icon(Icons.folder_open_outlined)),
              label: '壓縮檔',
              tooltip: ''),
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
