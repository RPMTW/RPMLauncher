import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Mod/CurseForge/ModPackHandler.dart';
import 'package:rpmlauncher/Mod/FTB/Handler.dart';
import 'package:rpmlauncher/Mod/FTB/ModPackClient.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';

class FTBModPack_ extends State<FTBModPack> {
  TextEditingController SearchController = TextEditingController();
  ScrollController ModPackScrollController = ScrollController();

  List<String> SortItems = [
    i18n.Format("edit.instance.mods.sort.curseforge.featured"),
    i18n.Format("edit.instance.mods.sort.curseforge.popularity"),
    i18n.Format("edit.instance.mods.sort.curseforge.update"),
    i18n.Format("edit.instance.mods.sort.curseforge.name"),
    i18n.Format("edit.instance.mods.sort.curseforge.author"),
    i18n.Format("edit.instance.mods.sort.curseforge.downloads")
  ];
  String SortItem =
      i18n.Format("edit.instance.mods.sort.curseforge.popularity");

  List<String> VersionItems = [];
  String VersionItem = i18n.Format('modpack.all_version');

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text("FTB 模組包下載頁面", textAlign: TextAlign.center),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(i18n.Format('modpack.search')),
              SizedBox(
                width: 12,
              ),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                controller: SearchController,
                decoration: InputDecoration(
                  hintText: i18n.Format('modpack.search.hint'),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 3.0),
                  ),
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              )),
              SizedBox(
                width: 12,
              ),
              ElevatedButton(
                style: new ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.deepPurpleAccent)),
                onPressed: () {
                  setState(() {});
                },
                child: Text(i18n.Format("gui.search")),
              ),
              SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(i18n.Format("edit.instance.mods.sort")),
                  DropdownButton<String>(
                    value: SortItem,
                    onChanged: (String? newValue) {
                      setState(() {
                        SortItem = newValue!;
                      });
                    },
                    items:
                        SortItems.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(i18n.Format("game.version")),
                  FutureBuilder(
                      future: FTBHandler.getVersions(),
                      builder: (context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          VersionItems = [i18n.Format('modpack.all_version')];
                          VersionItems.addAll(snapshot.data);

                          return DropdownButton<String>(
                            value: VersionItem,
                            onChanged: (String? newValue) {
                              setState(() {
                                VersionItem = newValue!;
                              });
                            },
                            items: VersionItems.map<DropdownMenuItem<String>>(
                                (String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }).toList(),
                          );
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      })
                ],
              ),
            ],
          )
        ],
      ),
      content: Container(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder(
            future: FTBHandler.getModPackList(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.length == 0) {
                  return Text(i18n.Format('modpack.found'),
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                }

                return ListView.builder(
                  controller: ModPackScrollController,
                  shrinkWrap: true,
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    return FutureBuilder(
                        future: get(Uri.parse(
                            "${FTBModPackAPI}/modpack/${snapshot.data[index]}")),
                        builder: (context, AsyncSnapshot packSnapshot) {
                          if (packSnapshot.hasData) {
                            Map data = json.decode(packSnapshot.data.body);

                            if (data['status'] == 'error') {
                              return Container();
                            }

                            bool VersionCkeck = VersionItem ==
                                    i18n.Format('modpack.all_version')
                                ? true
                                : (data['tags'] == null
                                    ? false
                                    : (data['tags'].any((tag) => tag['name']
                                        .toString()
                                        .contains(VersionItem))));

                            bool NameSearchCheck =
                                SearchController.text.isNotEmpty
                                    ? data['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(
                                            SearchController.text.toLowerCase())
                                    : true;

                            String Name = data["name"];
                            String ModDescription = data["synopsis"];
                            int FTBID = data["id"];

                            if (VersionCkeck && NameSearchCheck) {
                              return ListTile(
                                leading: Image.network(
                                  data["art"][0]["url"],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded
                                                      .toInt() /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                                      .toInt()
                                              : null,
                                    );
                                  },
                                ),
                                title: Text(Name),
                                subtitle: Text(ModDescription),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      child: Text(i18n.Format("gui.install")),
                                      onPressed: () {
                                        List Versions = data['versions'];
                                        Versions.sort((a, b) => a['updated']);
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(i18n.Format(
                                                  "edit.instance.mods.download.select.version")),
                                              content: Container(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      3,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      3,
                                                  child: ListView.builder(
                                                      itemCount:
                                                          Versions.length,
                                                      itemBuilder: (BuildContext
                                                              VersionsBuildContext,
                                                          int VersionsIndex) {
                                                        return FutureBuilder(
                                                            future: FTBHandler
                                                                .getVersionInfo(
                                                                    FTBID,
                                                                    Versions[
                                                                            VersionsIndex]
                                                                        ["id"]),
                                                            builder: (context,
                                                                AsyncSnapshot
                                                                    snapshot) {
                                                              if (snapshot
                                                                  .hasData) {
                                                                Map VersionInfo =
                                                                    snapshot
                                                                        .data;
                                                                return ListTile(
                                                                  title: Text(
                                                                      VersionInfo[
                                                                          "name"]),
                                                                  subtitle: FTBHandler
                                                                      .ParseReleaseType(
                                                                          VersionInfo[
                                                                              "type"]),
                                                                  onTap: () {
                                                                    showDialog(
                                                                      barrierDismissible:
                                                                          false,
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (context) =>
                                                                              Task(
                                                                        VersionInfo:
                                                                            VersionInfo,
                                                                        PackData:
                                                                            data,
                                                                      ),
                                                                    );
                                                                  },
                                                                );
                                                              } else {
                                                                return Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    CircularProgressIndicator()
                                                                  ],
                                                                );
                                                              }
                                                            });
                                                      })),
                                              actions: <Widget>[
                                                IconButton(
                                                  icon: Icon(Icons.close_sharp),
                                                  tooltip:
                                                      i18n.Format("gui.close"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(
                                            "${i18n.Format('modpack.name')}: $Name"),
                                        content: Text(
                                            "${i18n.Format('modpack.description')}: $ModDescription"),
                                      );
                                    },
                                  );
                                },
                              );
                            } else {
                              return Container();
                            }
                          } else {
                            return ListTile(
                                title:
                                    Center(child: CircularProgressIndicator()));
                          }
                        });
                  },
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.close_sharp),
          tooltip: i18n.Format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class FTBModPack extends StatefulWidget {
  @override
  FTBModPack_ createState() => FTBModPack_();
}

class Task extends StatefulWidget {
  final Map VersionInfo;
  final Map PackData;

  Task({required this.VersionInfo, required this.PackData}) {}

  @override
  Task_ createState() => Task_(VersionInfo: VersionInfo, PackData: PackData);
}

class Task_ extends State<Task> {
  final Map VersionInfo;
  final Map PackData;

  Task_({required this.VersionInfo, required this.PackData}) {}
  TextEditingController NameController = TextEditingController();
  Directory InstanceDir = GameRepository.getInstanceRootDir();
  Color BorderColour = Colors.red;

  @override
  void initState() {
    NameController.text = PackData["name"];
    if (PackData["name"] != "" ||
        !File(join(
                InstanceDir.absolute.path, PackData["name"], "instance.json"))
            .existsSync()) {
      BorderColour = Colors.blue;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text("新增模組包", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(i18n.Format("edit.instance.homepage.instance.name"),
                  style: TextStyle(fontSize: 18, color: Colors.amberAccent)),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: BorderColour, width: 5.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: BorderColour, width: 3.0),
                    ),
                  ),
                  controller: NameController,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    if (value == "" ||
                        File(join(InstanceDir.absolute.path, value,
                                "instance.json"))
                            .existsSync()) {
                      BorderColour = Colors.red;
                    } else {
                      BorderColour = Colors.blue;
                    }
                    setState(() {});
                  },
                ),
              )
            ],
          ),
          SizedBox(
            height: 12,
          ),
          Text("模組包名稱: ${PackData["name"]}"),
          Text("模組包版本: ${VersionInfo["name"]}"),
          Text("模組包遊戲版本: ${VersionInfo["targets"][1]["version"]}"),
        ],
      ),
      actions: [
        TextButton(
          child: Text(i18n.Format("gui.cancel")),
          onPressed: () {
            BorderColour = Colors.blue;
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: Text(i18n.Format("gui.confirm")),
            onPressed: () async {
              String LoaderID = VersionInfo["targets"][0]["name"];
              bool isFabric = LoaderID.startsWith(ModLoader().Fabric);

              String VersionID = VersionInfo["targets"][1]["version"];
              String LoaderVersionID = VersionInfo["targets"][0]["version"];

              Map Meta = await utility.getVanillaVersionMeta(VersionID);

              var NewInstanceConfig = {
                "name": NameController.text,
                "version": VersionID,
                "loader": isFabric ? ModLoader().Fabric : ModLoader().Forge,
                "java_version": Meta["javaVersion"]["majorVersion"],
                "loader_version": LoaderVersionID,
                'play_time': 0
              };

              File(join(InstanceDir.absolute.path, NameController.text,
                  "instance.json"))
                ..createSync(recursive: true)
                ..writeAsStringSync(json.encode(NewInstanceConfig));

              await get(Uri.parse(PackData['art'][0]['url'])).then((response) {
                File(join(InstanceDir.absolute.path, NameController.text,
                        "icon.png"))
                    .writeAsBytesSync(response.bodyBytes);
              });

              Navigator.of(context).pop();
              Navigator.push(
                context,
                new MaterialPageRoute(builder: (context) => LauncherHome()),
              );

              bool new_ = true;

              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return StatefulBuilder(builder: (context, setState) {
                      if (new_) {
                        FTBModPackClient.createClient(
                            InstanceDirName: NameController.text,
                            Meta: Meta,
                            VersionInfo: VersionInfo,
                            PackData: PackData,
                            context: context,
                            SetState: setState);
                        new_ = false;
                      }

                      if (Progress == 1) {
                        return AlertDialog(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(i18n.Format("gui.download.done")),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(i18n.Format("gui.close")))
                          ],
                        );
                      } else {
                        return WillPopScope(
                          onWillPop: () => Future.value(false),
                          child: AlertDialog(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Text(NowEvent, textAlign: TextAlign.center),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LinearProgressIndicator(
                                  value: Progress,
                                ),
                                Text("${(Progress * 100).toStringAsFixed(2)}%")
                              ],
                            ),
                            actions: <Widget>[],
                          ),
                        );
                      }
                    });
                  });
            })
      ],
    );
  }
}
