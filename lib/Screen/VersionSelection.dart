import 'dart:io';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Mod/CurseForge/ModPackHandler.dart';
import 'package:rpmlauncher/Screen/CurseForgeModPack.dart';
import 'package:rpmlauncher/Screen/FTBModPack.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:split_view/split_view.dart';

import '../main.dart';
import 'DownloadGameDialog.dart';

class VersionSelection_ extends State<VersionSelection> {
  int _selectedIndex = 0;
  bool showRelease = true;
  bool showSnapshot = false;
  bool showAlpha = false;
  bool showBeta = false;
  int chooseIndex = 0;
  TextEditingController versionsearchController = TextEditingController();

  String modLoaderName = I18n.format("version.list.mod.loader.vanilla");
  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
  late List<Widget> _widgetOptions;
  static Directory launcherFolder = dataHome;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  var nameController = TextEditingController();
  late var borderColour = Colors.lightBlue;

  @override
  Widget build(BuildContext context) {
    _widgetOptions = <Widget>[
      SplitView(
        children: [
          FutureBuilder(
              future: Uttily.vanillaVersions(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return ListView.builder(
                      itemCount: snapshot.data["versions"].length,
                      itemBuilder: (context, index) {
                        var listTile = ListTile(
                          title: Text(snapshot.data["versions"][index]["id"]),
                          tileColor: chooseIndex == index
                              ? Colors.white30
                              : Colors.white10,
                          onTap: () {
                            chooseIndex = index;
                            nameController.text = snapshot.data["versions"]
                                    [index]["id"]
                                .toString();
                            setState(() {});
                            if (File(join(
                                    GameRepository.getInstanceRootDir()
                                        .absolute
                                        .path,
                                    nameController.text,
                                    "instance.json"))
                                .existsSync()) {
                              borderColour = Colors.red;
                            }

                            showDialog(
                                context: context,
                                builder: (context) {
                                  return DownloadGameDialog(
                                    borderColour,
                                    nameController,
                                    snapshot.data["versions"][chooseIndex],
                                    ModLoaderUttily.getByString(modLoaderName),
                                  );
                                });
                          },
                        );
                        String type = snapshot.data["versions"][index]["type"];
                        String versionId =
                            snapshot.data["versions"][index]["id"];
                        bool inputVersionID =
                            versionId.contains(versionsearchController.text);
                        switch (type) {
                          case "release":
                            if (showRelease && inputVersionID) return listTile;
                            break;
                          case "snapshot":
                            if (showSnapshot && inputVersionID) return listTile;
                            break;
                          case "old_beta":
                            if (showBeta && inputVersionID) return listTile;
                            break;
                          case "old_alpha":
                            if (showAlpha && inputVersionID) return listTile;
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
                  controller: versionsearchController,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: I18n.format("version.list.filter"),
                  ),
                  onEditingComplete: () {
                    setState(() {});
                  },
                ),
              ),
              Text(
                I18n.format("version.list.mod.loader"),
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: modLoaderName,
                style: const TextStyle(color: Colors.lightBlue),
                onChanged: (String? Value) {
                  setState(() {
                    modLoaderName = Value!;
                  });
                },
                items: ModLoaderUttily.modLoaderNames.map<
                    DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(fontSize: 17.5)),
                  );
                }).toList(),
              ),
              ListTile(
                leading: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      showRelease = value!;
                    });
                  },
                  value: showRelease,
                ),
                title: Text(
                  I18n.format("version.list.show.release"),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                leading: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      showSnapshot = value!;
                    });
                  },
                  value: showSnapshot,
                ),
                title: Text(
                  I18n.format("version.list.show.snapshot"),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                leading: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      showBeta = value!;
                    });
                  },
                  value: showBeta,
                ),
                title: Text(
                  I18n.format("version.list.show.beta"),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                leading: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      showAlpha = value!;
                    });
                  },
                  value: showAlpha,
                ),
                title: Text(
                  I18n.format("version.list.show.alpha"),
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
          Text(I18n.format('modpack.install'),
              style: TextStyle(fontSize: 30, color: Colors.lightBlue),
              textAlign: TextAlign.center),
          Text(I18n.format('modpack.sourse'),
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
                    SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.asset("images/CurseForge.png")),
                    SizedBox(
                      width: 12,
                    ),
                    Text(I18n.format('modpack.from.curseforge'),
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
                    SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.asset("images/FTB.png")),
                    SizedBox(
                      width: 12,
                    ),
                    Text(I18n.format('modpack.from.ftb'),
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
                    Text(I18n.format('modpack.import'),
                        style: TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () async {
                  final file = await FileSelectorPlatform.instance
                      .openFile(acceptedTypeGroups: [
                    XTypeGroup(
                        label: I18n.format('modpack.file'),
                        extensions: ['zip']),
                  ]);

                  if (file == null) return;
                  showDialog(
                      context: context,
                      builder: (context) =>
                          CurseModPackHandler.setup(File(file.path)));
                },
              ),
            ],
          ))
        ],
      )
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text("請選擇安裝檔的類型"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: I18n.format("gui.back"),
          onPressed: () {
            navigator.pop();
          },
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: SizedBox(
                  width: 30,
                  height: 30,
                  child: Image.asset("images/Minecraft.png")),
              label: 'Minecraft',
              tooltip: ''),
          BottomNavigationBarItem(
              icon: SizedBox(width: 30, height: 30, child: Icon(Icons.folder)),
              label: I18n.format('modpack.title'),
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
