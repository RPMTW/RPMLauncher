import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftClient.dart';
import 'package:rpmlauncher/Mod/FTB/Handler.dart';
import 'package:rpmlauncher/Mod/FTB/ModPackClient.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

import '../main.dart';

class _FTBModPackState extends State<FTBModPack> {
  TextEditingController searchController = TextEditingController();
  ScrollController modPackScrollController = ScrollController();

  List<String> sortItems = [
    I18n.format("edit.instance.mods.sort.curseforge.featured"),
    I18n.format("edit.instance.mods.sort.curseforge.popularity"),
    I18n.format("edit.instance.mods.sort.curseforge.update"),
    I18n.format("edit.instance.mods.sort.curseforge.name"),
    I18n.format("edit.instance.mods.sort.curseforge.author"),
    I18n.format("edit.instance.mods.sort.curseforge.downloads")
  ];
  String sortItem =
      I18n.format("edit.instance.mods.sort.curseforge.popularity");

  List<String> versionItems = [];
  String versionItem = I18n.format('modpack.all_version');

  @override
  void initState() {
    super.initState();
  }

  @override
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
              Text(I18n.format('modpack.search')),
              SizedBox(
                width: 12,
              ),
              Expanded(
                  child: TextField(
                textAlign: TextAlign.center,
                controller: searchController,
                decoration: InputDecoration(
                  hintText: I18n.format('modpack.search.hint'),
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
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.deepPurpleAccent)),
                onPressed: () {
                  setState(() {});
                },
                child: Text(I18n.format("gui.search")),
              ),
              SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(I18n.format("edit.instance.mods.sort")),
                  DropdownButton<String>(
                    value: sortItem,
                    onChanged: (String? newValue) {
                      setState(() {
                        sortItem = newValue!;
                      });
                    },
                    items:
                        sortItems.map<DropdownMenuItem<String>>((String value) {
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
                  Text(I18n.format("game.version")),
                  FutureBuilder(
                      future: FTBHandler.getVersions(),
                      builder: (context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          versionItems = [I18n.format('modpack.all_version')];
                          versionItems.addAll(snapshot.data);

                          return DropdownButton<String>(
                            value: versionItem,
                            onChanged: (String? newValue) {
                              setState(() {
                                versionItem = newValue!;
                              });
                            },
                            items: versionItems
                                .map<DropdownMenuItem<String>>((String value) {
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
                          return Center(child: RWLLoading());
                        }
                      })
                ],
              ),
            ],
          )
        ],
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder(
            future: FTBHandler.getModPackList(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.isEmpty) {
                  return Text(I18n.format('modpack.found'),
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                }

                return ListView.builder(
                  controller: modPackScrollController,
                  shrinkWrap: true,
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    return FutureBuilder(
                        future: get(Uri.parse(
                            "$FTBModPackAPI/modpack/${snapshot.data[index]}")),
                        builder: (context, AsyncSnapshot packSnapshot) {
                          if (packSnapshot.hasData) {
                            Map data = json.decode(packSnapshot.data.body);

                            if (data['status'] == 'error') {
                              return Container();
                            }

                            bool versionCkeck = versionItem ==
                                    I18n.format('modpack.all_version')
                                ? true
                                : (data['tags'] == null
                                    ? false
                                    : (data['tags'].any((tag) => tag['name']
                                        .toString()
                                        .contains(versionItem))));

                            bool nameSearchCheck =
                                searchController.text.isNotEmpty
                                    ? data['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(
                                            searchController.text.toLowerCase())
                                    : true;

                            String name = data["name"];
                            String modDescription = data["synopsis"];
                            int FTBID = data["id"];

                            if (versionCkeck && nameSearchCheck) {
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
                                title: Text(name),
                                subtitle: Text(modDescription),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      child: Text(I18n.format("gui.install")),
                                      onPressed: () {
                                        List Versions = data['versions'];
                                        Versions.sort((a, b) => a['updated']);
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(I18n.format(
                                                  "edit.instance.mods.download.select.version")),
                                              content: SizedBox(
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
                                                                Map versionInfo =
                                                                    snapshot
                                                                        .data;
                                                                return ListTile(
                                                                  title: Text(
                                                                      versionInfo[
                                                                          "name"]),
                                                                  subtitle: FTBHandler
                                                                      .parseReleaseType(
                                                                          versionInfo[
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
                                                                        versionInfo:
                                                                            versionInfo,
                                                                        packData:
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
                                                                    RWLLoading()
                                                                  ],
                                                                );
                                                              }
                                                            });
                                                      })),
                                              actions: <Widget>[
                                                IconButton(
                                                  icon: Icon(Icons.close_sharp),
                                                  tooltip:
                                                      I18n.format("gui.close"),
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
                                            "${I18n.format('modpack.name')}: $name"),
                                        content: Text(
                                            "${I18n.format('modpack.description')}: $modDescription"),
                                      );
                                    },
                                  );
                                },
                              );
                            } else {
                              return Container();
                            }
                          } else {
                            return ListTile(title: Center(child: RWLLoading()));
                          }
                        });
                  },
                );
              } else {
                return Center(child: RWLLoading());
              }
            }),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.close_sharp),
          tooltip: I18n.format("gui.close"),
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
  _FTBModPackState createState() => _FTBModPackState();
}

class Task extends StatefulWidget {
  final Map versionInfo;
  final Map packData;

  const Task({required this.versionInfo, required this.packData});

  @override
  _TaskState createState() => _TaskState();
}

class _TaskState extends State<Task> {
  TextEditingController nameController = TextEditingController();
  Directory InstanceDir = GameRepository.getInstanceRootDir();
  Color borderColour = Colors.red;

  @override
  void initState() {
    nameController.text = widget.packData["name"];
    if (widget.packData["name"] != "" &&
        !File(join(
                InstanceDir.absolute.path, widget.packData["name"], "instance.json"))
            .existsSync()) {
      borderColour = Colors.blue;
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
              Text(I18n.format("edit.instance.homepage.instance.name"),
                  style: TextStyle(fontSize: 18, color: Colors.amberAccent)),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColour, width: 5.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: borderColour, width: 3.0),
                    ),
                  ),
                  controller: nameController,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    if (!Uttily.validInstanceName(value)) {
                      borderColour = Colors.red;
                    } else {
                      borderColour = Colors.blue;
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
          Text("模組包名稱: ${widget.packData["name"]}"),
          Text("模組包版本: ${widget.versionInfo["name"]}"),
          Text("模組包遊戲版本: ${widget.versionInfo["targets"][1]["version"]}"),
        ],
      ),
      actions: [
        TextButton(
          child: Text(I18n.format("gui.cancel")),
          onPressed: () {
            borderColour = Colors.blue;
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: Text(I18n.format("gui.confirm")),
            onPressed: () async {
              String loaderID = widget.versionInfo["targets"][0]["name"];
              bool isFabric =
                  loaderID.startsWith(ModLoaders.fabric.fixedString);

              String VersionID = widget.versionInfo["targets"][1]["version"];
              String loaderVersionID = widget.versionInfo["targets"][0]["version"];

              Map Meta = await Uttily.getVanillaVersionMeta(VersionID);

              var NewInstanceConfig = {
                "name": nameController.text,
                "version": VersionID,
                "loader": (isFabric ? ModLoaders.fabric : ModLoaders.forge)
                    .fixedString,
                "java_version": Meta["javaVersion"]["majorVersion"],
                "loader_version": loaderVersionID,
                'play_time': 0
              };

              File(join(InstanceDir.absolute.path, nameController.text,
                  "instance.json"))
                ..createSync(recursive: true)
                ..writeAsStringSync(json.encode(NewInstanceConfig));

              await get(Uri.parse(widget.packData['art'][0]['url'])).then((response) {
                File(join(InstanceDir.absolute.path, nameController.text,
                        "icon.png"))
                    .writeAsBytesSync(response.bodyBytes);
              });

              navigator.pop();
              navigator.push(PushTransitions(builder: (context) => HomePage()));

              bool new_ = true;

              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return StatefulBuilder(builder: (context, setState) {
                      if (new_) {
                        FTBModPackClient.createClient(
                            instanceDirName: nameController.text,
                            meta: Meta,
                            versionInfo: widget.versionInfo,
                            packData: widget.packData,
                            SetState: setState);
                        new_ = false;
                      }

                      if (finish && infos.progress == 1.0) {
                        return AlertDialog(
                          title: Text(I18n.format("gui.download.done")),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(I18n.format("gui.close")))
                          ],
                        );
                      } else {
                        return WillPopScope(
                          onWillPop: () => Future.value(false),
                          child: AlertDialog(
                            title: Text(nowEvent, textAlign: TextAlign.center),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LinearProgressIndicator(
                                  value: infos.progress,
                                ),
                                Text(
                                    "${(infos.progress * 100).toStringAsFixed(2)}%")
                              ],
                            ),
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
