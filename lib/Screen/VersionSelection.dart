import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Mod/CurseForge/ModPackHandler.dart';
import 'package:rpmlauncher/Screen/CurseForgeModPack.dart';
import 'package:rpmlauncher/Screen/FTBModPack.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:file_selector/file_selector.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:split_view/split_view.dart';

import '../main.dart';
import '../path.dart';
import 'DownloadGameDialog.dart';

var httpClient = new HttpClient();

class VersionSelection_ extends State<VersionSelection> {
  int _selectedIndex = 0;
  bool ShowRelease = true;
  bool ShowSnapshot = false;
  bool ShowAlpha = false;
  bool ShowBeta = false;
  int choose_index = 0;
  var VersionSearchController = new TextEditingController();

  var ModLoaderName = i18n.format("version.list.mod.loader.vanilla");
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
      SplitView(
        children: [
          FutureBuilder(
              future: utility.VanillaVersions(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return ListView.builder(
                      itemCount: snapshot.data["versions"].length,
                      itemBuilder: (context, index) {
                        var list_tile = ListTile(
                          title: Text(snapshot.data["versions"][index]["id"]),
                          tileColor: choose_index == index
                              ? Colors.white30
                              : Colors.white10,
                          onTap: () {
                            choose_index = index;
                            name_controller.text = snapshot.data["versions"]
                                    [index]["id"]
                                .toString();
                            setState(() {});
                            if (File(join(InstanceDir.absolute.path,
                                    name_controller.text, "instance.json"))
                                .existsSync()) {
                              border_colour = Colors.red;
                            }

                            showDialog(
                                context: context,
                                builder: (context) {
                                  return DownloadGameDialog(
                                      border_colour,
                                      name_controller,
                                      snapshot.data["versions"][choose_index],
                                      ModLoaderName,
                                      context);
                                });
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
                  return Center(child: RWLLoading());
                }
              }),
          Column(
            children: [
              SizedBox(height: 10),
              SizedBox(
                height: 45,
                width: 200,
                child: TextField(
                  controller: VersionSearchController,
                  textAlign: TextAlign.center,
                  style: new TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: i18n.format("version.list.filter"),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              Text(
                i18n.format("version.list.mod.loader"),
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: ModLoaderName,
                style: const TextStyle(color: Colors.lightBlue),
                onChanged: (String? newValue) {
                  setState(() {
                    ModLoaderName = newValue!;
                  });
                },
                items: ModLoader()
                    .ModLoaderNames
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: new TextStyle(fontSize: 17.5)),
                  );
                }).toList(),
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
                  i18n.format("version.list.show.release"),
                  style: TextStyle(
                    fontSize: 18,
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
                  i18n.format("version.list.show.snapshot"),
                  style: TextStyle(
                    fontSize: 18,
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
                  i18n.format("version.list.show.beta"),
                  style: TextStyle(
                    fontSize: 18,
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
                  i18n.format("version.list.show.alpha"),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
        gripSize: 0,
        controller: SplitViewController(weights: [0.83]),
        viewMode: SplitViewMode.Horizontal,
      ),
      ListView(
        children: [
          Text(i18n.format('modpack.install'),
              style: TextStyle(fontSize: 30, color: Colors.lightBlue),
              textAlign: TextAlign.center),
          Text(i18n.format('modpack.sourse'),
              textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
          SizedBox(
            height: 12,
          ),
          Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                        backgroundColor: Colors.transparent,
                        onPressed: () {
                          // Navigator.pop(context);
                        },
                        child: Image.asset("images/CurseForge.png")),
                    SizedBox(
                      width: 12,
                    ),
                    Text(i18n.format('modpack.from.curseforge'),
                        style: TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) => CurseForgeModPack());
                },
              ),
              SizedBox(
                height: 12,
              ),
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                        backgroundColor: Colors.transparent,
                        onPressed: () {
                          // Navigator.pop(context);
                        },
                        child: Image.asset("images/FTB.png")),
                    SizedBox(
                      width: 12,
                    ),
                    Text(i18n.format('modpack.from.ftb'),
                        style: TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () {
                  showDialog(
                      context: context, builder: (context) => FTBModPack());
                },
              ),
              SizedBox(
                height: 12,
              ),
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                        backgroundColor: Colors.deepPurpleAccent,
                        onPressed: () {},
                        child: Icon(Icons.computer)),
                    SizedBox(
                      width: 12,
                    ),
                    Text(i18n.format('modpack.import'),
                        style: TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () async {
                  final file = await FileSelectorPlatform.instance
                      .openFile(acceptedTypeGroups: [
                    XTypeGroup(
                        label: i18n.format('modpack.file'),
                        extensions: ['zip']),
                  ]);

                  if (file == null) return;
                  showDialog(
                      context: context,
                      builder: (context) =>
                          CurseModPackHandler.Setup(File(file.path)));
                },
              ),
            ],
          ))
        ],
      )
    ];
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("請選擇安裝檔的類型"),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: i18n.format("gui.back"),
          onPressed: () {
            navigator.pop();
          },
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
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
                  width: 30, height: 30, child: new Icon(Icons.folder)),
              label: i18n.format('modpack.title'),
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
