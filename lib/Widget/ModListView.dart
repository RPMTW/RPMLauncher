import 'dart:convert';
import 'dart:io';

import 'package:RPMLauncher/MCLauncher/APIs.dart';
import 'package:RPMLauncher/Mod/CurseForge/Handler.dart';
import 'package:RPMLauncher/Model/ModInfo.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:RPMLauncher/Utility/utility.dart';
import 'package:RPMLauncher/path.dart';
import 'package:archive/archive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

class ModListView extends StatefulWidget {
  late List<FileSystemEntity> files;
  late TextEditingController ModSearchController;
  late Map instanceConfig;

  ModListView(files_, ModSearchController_, instanceConfig_) {
    files = files_;
    ModSearchController = ModSearchController_;
    instanceConfig = instanceConfig_;
  }

  @override
  ModListView_ createState() =>
      ModListView_(files, ModSearchController, instanceConfig);
}

class ModListView_ extends State<ModListView> {
  static List<FileSystemEntity> files = [];
  late TextEditingController ModSearchController;
  late Map instanceConfig;

  static late File ModIndex_;
  static late Map ModIndex;
  static List<ModInfo> ModInfos = [];
  static List<ModInfo> AllModInfos = [];
  late var setModState;

  ModListView_(files_, ModSearchController_, instanceConfig_) {
    files = files_;
    ModSearchController = ModSearchController_;
    instanceConfig = instanceConfig_;
  }

  @override
  void initState() {
    ModIndex_ = File(join(configHome.absolute.path, "mod_index.json"));
    if (!ModIndex_.existsSync()) {
      ModIndex_.writeAsStringSync("{}");
    }
    ModIndex = json.decode(ModIndex_.readAsStringSync());
    super.initState();
  }

  static Future<ModInfo> GetModInfo(
      File ModFile, String ModHash, Map ModIndex, File ModIndex_) async {
    final unzipped =
        ZipDecoder().decodeBytes(File(ModFile.absolute.path).readAsBytesSync());
    late String ModType;
    Map ModJson = {};
    for (final file in unzipped) {
      final filename = file.name;
      if (file.isFile) {
        if (filename == "fabric.mod.json") {
          final data = file.content as List<int>;
          ModType = ModLoader().Fabric;
          //Fabric Mod Info File
          try {
            ModJson =
                json.decode(Utf8Decoder(allowMalformed: true).convert(data));
          } catch (e) {
            print(e);
            var modInfo = ModInfo(
                loader: ModLoader().Unknown,
                name: ModFile.absolute.path
                    .split(Platform.pathSeparator)
                    .last
                    .replaceFirst(".jar", "")
                    .replaceFirst(".disable", ""),
                description: 'unknown',
                version: 'unknown',
                curseID: null,
                file: ModFile.path);
            ModIndex[ModHash] = modInfo.toList();
            ModIndex_.writeAsStringSync(json.encode(ModIndex));
          }

          try {
            if (ModJson.containsKey("icon")) {
              for (var i in unzipped) {
                if (i.name == ModJson["icon"]) {
                  File(join(Directory.systemTemp.path, "RPMLauncher_Icon",
                      "$ModHash.png"))
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(i.content as List<int>);
                }
              }
            }
          } catch (err) {
            print(err);
          }

          var modInfo = ModInfo(
              loader: ModType,
              name: ModJson["name"],
              description: ModJson["description"],
              version: ModJson["version"],
              curseID: null,
              file: ModFile.path);
          ModIndex[ModHash] = modInfo.toList();
          ModIndex_.writeAsStringSync(json.encode(ModIndex));
          return modInfo;
        } else if (filename == "mcmod.info") {
          final data = file.content as List<int>;
          ModType = ModLoader().Forge;
          //Forge Mod Info File (1.7.10 -> 1.12.2)
          ModJson =
              json.decode(Utf8Decoder(allowMalformed: true).convert(data))[0];

          if (ModJson["logoFile"].toString().isNotEmpty) {
            for (var i in unzipped) {
              if (i.name == ModJson["logoFile"]) {
                File(join(Directory.systemTemp.path, "RPMLauncher_Icon",
                    "$ModHash.png"))
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(i.content as List<int>);
              }
            }
          }

          var modInfo = ModInfo(
              loader: ModType,
              name: ModJson["name"],
              description: ModJson["description"],
              version: ModJson["version"],
              curseID: null,
              file: ModFile.path);
          ModIndex[ModHash] = modInfo.toList();
          ModIndex_.writeAsStringSync(json.encode(ModIndex));
          return modInfo;
        }
      }
    }
    var modInfo = ModInfo(
        loader: ModLoader().Unknown,
        name: ModFile.absolute.path
            .split(Platform.pathSeparator)
            .last
            .replaceFirst(".jar", "")
            .replaceFirst(".disable", ""),
        description: 'unknown',
        version: 'unknown',
        curseID: null,
        file: ModFile.path);
    ModIndex[ModHash] = modInfo.toList();
    ModIndex_.writeAsStringSync(json.encode(ModIndex));
    return modInfo;
  }

  static List<ModInfo> GetModInfos(args) {
    List<FileSystemEntity> files = args[0];
    Map ModIndex = args[1];
    File ModIndex_ = args[2];
    AllModInfos.clear();
    files.forEach((file) async {
      File ModFile = File(file.path);
      final ModHash = utility.murmurhash2(ModFile).toString();
      if (ModIndex.containsKey(ModHash)) {
        List infoList = ModIndex[ModHash];
        infoList.add(ModFile.path);
        ModInfo modInfo = ModInfo.fromList(infoList);
        AllModInfos.add(modInfo);
      } else {
        List infoList =
            (await GetModInfo(ModFile, ModHash, ModIndex, ModIndex_)).toList();
        ModIndex[ModHash] = infoList;
        infoList.add(ModFile.path);
        ModInfo modInfo = ModInfo.fromList(infoList);
        AllModInfos.add(modInfo);
      }
    });
    return AllModInfos;
  }

  void filterSearchResults(String query) {
    ModInfos = AllModInfos.where((modInfo) {
      String Name = modInfo.name ?? "";
      final NameLower = Name.toLowerCase();
      final searchLower = query.toLowerCase();
      return NameLower.contains(searchLower);
    }).toList();
    setModState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      controller: ScrollController(),
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 12,
            ),
            Expanded(
                child: TextField(
              textAlign: TextAlign.center,
              controller: ModSearchController,
              decoration: InputDecoration(
                hintText: "請輸入模組名稱來搜尋",
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue, width: 5.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue, width: 3.0),
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
                filterSearchResults(ModSearchController.text);
              },
              child: Text(i18n.Format("gui.search")),
            ),
            SizedBox(
              width: 12,
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        FutureBuilder(
            future: compute(GetModInfos, [files, ModIndex, ModIndex_]),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData &&
                  snapshot.data.length == files.length &&
                  snapshot.data != null) {
                AllModInfos = snapshot.data;
                ModInfos = snapshot.data;
                return StatefulBuilder(builder: (context, setModState_) {
                  setModState = setModState_;
                  return ListView.builder(
                      cacheExtent: 0.5,
                      controller: ScrollController(),
                      shrinkWrap: true,
                      itemCount: ModInfos.length,
                      itemBuilder: (context, index) {
                        try {
                          return ModListTile(ModInfos[index], context);
                        } catch (error) {
                          print(error);
                          return Container();
                        }
                      });
                });
              } else if (snapshot.hasError) {
                print(snapshot.error);
                return Text(snapshot.error.toString());
              } else {
                return Column(
                  children: [
                    SizedBox(height: 20),
                    CircularProgressIndicator(),
                  ],
                );
              }
            }),
      ],
    );
  }

  Widget ModListTile(ModInfo modInfo, BuildContext context) {
    File ModFile = File(modInfo.file);
    String ModName = modInfo.name ?? "";
    final String ModHash = utility.murmurhash2(ModFile).toString();
    File ImageFile = File(
        join(Directory.systemTemp.path, "RPMLauncher_Icon", "$ModHash.png"));
    late Widget image;

    if (ImageFile.existsSync()) {
      image = Image.file(ImageFile);
    } else {
      image = Icon(Icons.image, size: 50);
    }

    return ListTile(
      leading: image,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Builder(
          //   builder: (context) {
          //     if (modInfo.loader == instanceConfig["loader"]) {
          //       return Container();
          //     } else {
          //       return Positioned(
          //         top: 7,
          //         left: 7,
          //         child: Tooltip(
          //           child: Icon(Icons.warning),
          //           message:
          //               "This mod is a ${modInfo.loader} mod, this is a ${instanceConfig["loader"]} instance",
          //         ),
          //       );
          //     }
          //   },
          // ),
          Text(ModName),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModSwitchBox(ModFile),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(i18n.Format("gui.tips.info")),
                    content: Text("您確定要刪除此模組嗎？ (此動作將無法復原)"),
                    actions: [
                      TextButton(
                        child: Text(i18n.Format("gui.cancel")),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                          child: Text(i18n.Format("gui.confirm")),
                          onPressed: () {
                            Navigator.of(context).pop();
                            ModFile.deleteSync(recursive: true);
                          })
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
                    i18n.Format("edit.instance.mods.list.name") + ModName,
                    textAlign: TextAlign.center),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(i18n.Format("edit.instance.mods.list.description") +
                        (modInfo.description ?? "")),
                    Text(i18n.Format("edit.instance.mods.list.version") +
                        modInfo.version.toString()),
                    Builder(builder: (content) {
                      int? CurseID = modInfo.curseID;
                      if (CurseID == null) {
                        return FutureBuilder(
                            future: CurseForgeHandler.CheckFingerprint(ModFile),
                            builder: (content, AsyncSnapshot snapshot) {
                              if (snapshot.hasData) {
                                CurseID = snapshot.data;
                                List NewModInfo = modInfo.toList();
                                NewModInfo[4] = CurseID;
                                ModIndex[ModHash] = NewModInfo;
                                ModIndex_.writeAsStringSync(
                                    json.encode(ModIndex));
                                return CurseForgeInfo(CurseID ?? 0);
                              } else {
                                return CircularProgressIndicator();
                              }
                            });
                      } else {
                        return CurseForgeInfo(CurseID);
                      }
                    }),
                  ],
                ));
          },
        );
      },
    );
  }

  Widget ModSwitchBox(File ModFile) {
    bool ModSwitch = !ModFile.path.endsWith(".disable");
    return StatefulBuilder(builder: (context, setSwitchState) {
      return Checkbox(
          value: ModSwitch,
          activeColor: Colors.blueAccent,
          onChanged: (value) {
            if (ModSwitch) {
              ModSwitch = false;
              String Name = ModFile.absolute.path + ".disable";
              ModFile.rename(Name);
              ModFile = File(Name);
              setSwitchState(() {});
            } else {
              ModSwitch = true;
              String Name = ModFile.absolute.path.split(".disable")[0];
              ModFile.rename(Name);
              ModFile = File(Name);
              setSwitchState(() {});
            }
          });
    });
  }
}

Widget CurseForgeInfo(int CurseID) {
  return Builder(builder: (content) {
    if (CurseID != 0) {
      return IconButton(
        onPressed: () async {
          Response response =
              await get(Uri.parse("${CurseForgeModAPI}/addon/${CurseID}"));
          String PageUrl = json.decode(response.body)["websiteUrl"];
          if (await canLaunch(PageUrl)) {
            launch(PageUrl);
          } else {
            print("Can't open the url $PageUrl");
          }
        },
        icon: Icon(Icons.open_in_new),
        tooltip: "在 CurseForge 中檢視此模組",
      );
    } else {
      return Container();
    }
  });
}
