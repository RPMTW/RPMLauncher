import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Model/ModInfo.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/path.dart';
import 'package:archive/archive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';
import 'package:url_launcher/url_launcher.dart';

class ModListView extends StatefulWidget {
  late List<FileSystemEntity> files;
  late TextEditingController ModSearchController;
  late Map instanceConfig;
  late var ModDir;
  ModListView(List<FileSystemEntity> files_, ModSearchController_,
      instanceConfig_, Directory ModDir_) {
    files = files_.where((file) => file.existsSync()).toList();
    ModSearchController = ModSearchController_;
    instanceConfig = instanceConfig_;
    ModDir = ModDir_;
  }

  @override
  ModListView_ createState() =>
      ModListView_(files, ModSearchController, instanceConfig, ModDir);
}

class ModListView_ extends State<ModListView> {
  static List<FileSystemEntity> files = [];
  late TextEditingController ModSearchController;
  late Map instanceConfig;
  late Directory ModDir;
  static late File ModIndex_;
  static late Map ModIndex;
  static List<ModInfo> ModInfos = [];
  static List<ModInfo> AllModInfos = [];
  late var setModState;
  late File ConflictMod_;
  late Map ConflictMod;
  ModListView_(files_, ModSearchController_, instanceConfig_, ModDir_) {
    files = files_;
    ModSearchController = ModSearchController_;
    instanceConfig = instanceConfig_;
    ModDir = ModDir_;
  }

  @override
  void initState() {
    ConflictMod_=File(join(ModDir.absolute.path,".conflict_mod"));
    if (ConflictMod_.existsSync()){
      ConflictMod_.deleteSync();
    }
    ConflictMod_.createSync();
    ConflictMod_.writeAsStringSync("{}");

    ModIndex_ = File(join(dataHome.absolute.path, "mod_index.json"));
    if (!ModIndex_.existsSync()) {
      ModIndex_.writeAsStringSync("{}");
    }
    ModIndex = json.decode(ModIndex_.readAsStringSync());
    super.initState();
  }

  static Future<ModInfo> GetModInfo(File ModFile, String ModHash, Map ModIndex,
      File ModIndex_, File ConflictMod_) async {
    Map<String, dynamic> ConflictMod =
        json.decode(ConflictMod_.readAsStringSync());
    final unzipped =
        ZipDecoder().decodeBytes(File(ModFile.absolute.path).readAsBytesSync());
    late String ModType;
    Map ModInfoMap = {};
    var conflict = {};
    for (final file in unzipped) {
      final filename = file.name;
      if (file.isFile) {
        if (filename == "fabric.mod.json") {
          final data = file.content as List<int>;
          ModType = ModLoader().Fabric;
          //Fabric Mod Info File
          try {
            ModInfoMap =
                json.decode(Utf8Decoder(allowMalformed: true).convert(data));
          } catch (e) {
            print("About line 86: " + e.toString());
            var modInfo = ModInfo(
                loader: ModType,
                name: ModFile.absolute.path
                    .split(Platform.pathSeparator)
                    .last
                    .replaceFirst(".jar", "")
                    .replaceFirst(".disable", ""),
                description: 'unknown',
                version: 'unknown',
                curseID: null,
                file: ModFile.path,
                conflicts: {},
                id: "unknown");
            ModIndex[ModHash] = modInfo.toList();
            ModIndex_.writeAsStringSync(json.encode(ModIndex));
            return modInfo;
          }
          try {
            if (ModInfoMap.containsKey("icon")) {
              for (var i in unzipped) {
                if (i.name == ModInfoMap["icon"]) {
                  File(join(
                      dataHome.absolute.path, "ModTempIcons", "$ModHash.png"))
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(i.content as List<int>);
                }
              }
            }
          } catch (err) {
            print("About line 117: " + err.toString());
          }
          ConflictMod[ModInfoMap["id"]] = {};
          conflict = {};
          if (ModInfoMap.containsKey("conflicts")) {
            ConflictMod[ModInfoMap["id"]] .addAll(ModInfoMap["conflicts"] ?? {});
            conflict.addAll(ModInfoMap["conflicts"] ?? {});
          }
          if (ModInfoMap.containsKey("breaks")) {
            ConflictMod[ModInfoMap["id"]].addAll(ModInfoMap["breaks"] ?? {});
            conflict.addAll(ModInfoMap["breaks"] ?? {});

          }
          var modInfo = ModInfo(
              loader: ModType,
              name: ModInfoMap["name"],
              description: ModInfoMap["description"],
              version: ModInfoMap["version"],
              curseID: null,
              file: ModFile.path,
              conflicts: conflict,
              id: ModInfoMap["id"]);
          ModIndex[ModHash] = modInfo.toList();
          ModIndex_.writeAsStringSync(json.encode(ModIndex));

          ConflictMod_.writeAsStringSync(jsonEncode(ConflictMod));
          return modInfo;
        } else if (filename.contains("META-INF/mods.toml")) {
          //Forge Mod Info File (1.13 -> 1.17.1+)
          final data = file.content as List<int>;
          ModType = ModLoader().Forge;
          TomlDocument ModToml;
          try {
            ModToml = TomlDocument.parse(
                Utf8Decoder(allowMalformed: true).convert(data));
          } catch (e) {
            print("About line 139: " + e.toString());
            var modInfo = ModInfo(
                loader: ModType,
                name: ModFile.absolute.path
                    .split(Platform.pathSeparator)
                    .last
                    .replaceFirst(".jar", "")
                    .replaceFirst(".disable", ""),
                description: 'unknown',
                version: 'unknown',
                curseID: null,
                file: ModFile.path,
                conflicts: {},
                id: "unknown");
            ModIndex[ModHash] = modInfo.toList();
            ModIndex_.writeAsStringSync(json.encode(ModIndex));
            return modInfo;
          }

          ModInfoMap = ModToml.toMap();

          final Map ModInfo_ = ModInfoMap["mods"][0];

          if (ModInfoMap["logoFile"].toString().isNotEmpty) {
            for (var i in unzipped) {
              if (i.name == ModInfoMap["logoFile"]) {
                File(join(
                    dataHome.absolute.path, "ModTempIcons", "$ModHash.png"))
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(i.content as List<int>);
              }
            }
          }

          var modInfo = ModInfo(
              loader: ModType,
              name: ModInfo_["displayName"],
              description: ModInfo_["description"],
              version: ModInfo_["version"],
              curseID: null,
              file: ModFile.path,
              conflicts: {},
              id: ModInfo_["modId"]);
          ModIndex[ModHash] = modInfo.toList();
          ModIndex_.writeAsStringSync(json.encode(ModIndex));
          return modInfo;
        } else if (filename == "mcmod.info") {
          final data = file.content as List<int>;
          ModType = ModLoader().Forge;
          //Forge Mod Info File (1.7.10 -> 1.12.2)
          ModInfoMap =
              json.decode(Utf8Decoder(allowMalformed: true).convert(data))[0];

          if (ModInfoMap["logoFile"].toString().isNotEmpty) {
            for (var i in unzipped) {
              if (i.name == ModInfoMap["logoFile"]) {
                File(join(
                    dataHome.absolute.path, "ModTempIcons", "$ModHash.png"))
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(i.content as List<int>);
              }
            }
          }

          var modInfo = ModInfo(
              loader: ModType,
              name: ModInfoMap["name"],
              description: ModInfoMap["description"],
              version: ModInfoMap["version"],
              curseID: null,
              file: ModFile.path,
              conflicts: {},
              id: ModInfoMap["modid"]);
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
        file: ModFile.path,
        conflicts: {},
        id: 'unknown');
    ModIndex[ModHash] = modInfo.toList();
    ModIndex_.writeAsStringSync(json.encode(ModIndex));

    return modInfo;
  }

  static List<ModInfo> GetModInfos(args) {
    List<FileSystemEntity> files = args[0];
    Map ModIndex = args[1];
    File ModIndex_ = args[2];
    File ConflictMod_ = args[3];
    var ConflictMod=json.decode(ConflictMod_.readAsStringSync());
    AllModInfos.clear();
    files.forEach((file) async {
      File ModFile = File(file.path);
      final ModHash = utility.murmurhash2(ModFile).toString();
      if (ModIndex.containsKey(ModHash)) {
        List infoList = ModIndex[ModHash];

        infoList.add(ModFile.path);
        ModInfo modInfo = ModInfo.fromList(infoList);
        ConflictMod[modInfo.id]=modInfo.conflicts;

        ConflictMod_.writeAsStringSync(json.encode(ConflictMod));
        AllModInfos.add(modInfo);
      } else {
        List infoList = (await GetModInfo(
                ModFile, ModHash, ModIndex, ModIndex_, ConflictMod_))
            .toList();
        infoList.add(ModFile.path);
        ModInfo modInfo = ModInfo.fromList(infoList);
        AllModInfos.add(modInfo);
      }
    });
    return AllModInfos;
  }

  void filterSearchResults(String query) {
    ModInfos = AllModInfos.where((modInfo) {
      String Name = modInfo.name;
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
            future: compute(
                GetModInfos, [files, ModIndex, ModIndex_, ConflictMod_]),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData &&
                  snapshot.data.length == files.length &&
                  snapshot.data != null) {
                (snapshot.data as List<ModInfo>).sort((a, b) {
                  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                });
                AllModInfos = snapshot.data;
                ModInfos = AllModInfos;
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
                          print("About line 337: " + error.toString());
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
    Map<String, dynamic> ConflictMod =
        json.decode(ConflictMod_.readAsStringSync());

    File ModFile = File(modInfo.file);
    String ModName = modInfo.name;
    final String ModHash = utility.murmurhash2(ModFile).toString();
    File ImageFile =
        File(join(dataHome.absolute.path, "ModTempIcons", "$ModHash.png"));
    late Widget image;
    if (ImageFile.existsSync()) {
      image = Image.file(ImageFile, fit: BoxFit.fill);
    } else {
      image = Icon(Icons.image, size: 50);
    }

    return ListTile(
      leading: SizedBox(child: image, width: 50, height: 50),
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
          Builder(
            builder: (context) {
              List a=[];
              for (var i in Iterable<int>.generate(ConflictMod.keys.length )
                  .toList()) {
                //print(ConflictMod.keys.toList()[i]);
                for (var ii in ConflictMod[ConflictMod.keys.toList()[i]].keys) {
                  print(ConflictMod[ConflictMod.keys.toList()[i]]);
                  print(modInfo.id);
                  if (ii == modInfo.id) {
                    a.add(ConflictMod.keys.toList()[i]);
                  }
                }
              }
              if (a.isEmpty){
              return Container();}else{
                return Tooltip(
                  message: "This mod will conflict with " +
                      a.toString(),
                  child: Icon(Icons.warning),
                );
              }
            },
          ),
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
