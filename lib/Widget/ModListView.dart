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
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

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
  late List<FileSystemEntity> files;
  late TextEditingController ModSearchController;
  late Map instanceConfig;

  late File ModIndex_;
  late Map<String, dynamic> ModIndex;
  late List<ModInfo> ModInfos = [];
  late List<ModInfo> AllModInfos = [];
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

  static GetModInfo(File ModFile) async {
    late Directory _ConfigFolder = configHome;
    var ModIndex_ = File(join(_ConfigFolder.absolute.path, "mod_index.json"));

    if (!ModIndex_.existsSync()) {
      ModIndex_
        ..createSync()
        ..writeAsStringSync("{}");
    }

    Map ModIndex = json.decode(ModIndex_.readAsStringSync());

    final ModHash = utility.murmurhash2(ModFile).toString();
    try {
      final unzipped = ZipDecoder()
          .decodeBytes(File(ModFile.absolute.path).readAsBytesSync());
      late var ModType;
      for (final file in unzipped) {
        var ModJson;
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          if (filename == "fabric.mod.json") {
            int CurseID = await CurseForgeHandler.CheckFingerprint(
                File(ModFile.absolute.path));
            ModType = ModLoader().Fabric;
            //Fabric Mod Info File
            try {
              ModJson =
                  json.decode(Utf8Decoder(allowMalformed: true).convert(data));
              for (var i in unzipped) {
                if (i.name == ModJson["icon"]) {
                  File(join(Directory.systemTemp.path, "RPMLauncher_Icon",
                      "$ModHash.png"))
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(i.content as List<int>);
                }
              }
              var modInfo = ModInfo(
                  loader: ModType,
                  name: ModJson["name"],
                  description: ModJson["description"],
                  version: ModJson["version"],
                  curseID: CurseID,
                  file: ModFile);
              ModIndex[ModHash] = modInfo.toList();
              ModIndex_.writeAsStringSync(json.encode(ModIndex));
              return modInfo;
            } on FormatException {
              return ModInfo(
                  loader: ModType,
                  name: ModFile.absolute.path
                      .split(Platform.pathSeparator)
                      .last
                      .replaceFirst(".jar", "")
                      .replaceFirst(".disable", ""),
                  description: 'unknown',
                  version: 'unknown',
                  curseID: CurseID,
                  file: ModFile);
            }
          } else if (filename == "mcmod.info") {
            int CurseID = await CurseForgeHandler.CheckFingerprint(
                File(ModFile.absolute.path));
            ModType = ModLoader().Forge;
            //Forge Mod Info File (1.7.10 -> 1.12.2)
            ModJson =
                json.decode(Utf8Decoder(allowMalformed: true).convert(data))[0];

            for (var i in unzipped) {
              if (i.name == ModJson["logoFile"]) {
                File(join(Directory.systemTemp.path, "RPMLauncher_Icon",
                    "$ModHash.png"))
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(i.content as List<int>);
              }
            }

            var modInfo = ModInfo(
                loader: ModType,
                name: ModJson["name"],
                description: ModJson["description"],
                version: ModJson["version"],
                curseID: CurseID,
                file: ModFile);
            ModIndex[ModHash] = modInfo.toList();
            ModIndex_.writeAsStringSync(json.encode(ModIndex));
            return modInfo;
          } else {
            ModType = ModLoader().Unknown;
          }
        }
      }
      if (ModType == ModLoader().Unknown) {
        return ModInfo(
            loader: ModType,
            name: ModFile.absolute.path
                .split(Platform.pathSeparator)
                .last
                .replaceFirst(".jar", "")
                .replaceFirst(".disable", ""),
            description: 'unknown',
            version: 'unknown',
            curseID: 0,
            file: ModFile);
      }
    } on FileSystemException {
      print("A dir detected instead of a file");
    } catch (e) {
      print(e);
    }
  }

  Future<List<ModInfo>> GetModInfos() async {
    ModInfos.clear();
    AllModInfos.clear();
    files.forEach((file) async {
      File ModFile = File(file.path);
      if (!ModFile.existsSync() ||
          !path.extension(ModFile.path, 2).contains(".jar")) return;
      final ModHash = utility.murmurhash2(ModFile).toString();
      if (ModIndex.containsKey(ModHash)) {
        ModIndex[ModHash].add(ModFile);
        ModInfo modInfo = ModInfo.fromList(ModIndex[ModHash]);
        AllModInfos.add(modInfo);
      } else {
        var info = await compute(GetModInfo, ModFile);
        info = info.toList();
        info.add(ModFile);
        ModInfo modInfo = ModInfo.fromList(info);
        AllModInfos.add(modInfo);
      }
    });
    ModInfos.addAll(AllModInfos);
    return ModInfos;
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      List<ModInfo> dummyListData = [];
      AllModInfos.forEach((ModInfo) {
        if (utility.containsIgnoreCase(ModInfo.name, query)) {
          dummyListData.add(ModInfo);
        }
      });
      setModState(() {
        ModInfos.clear();
        ModInfos.addAll(dummyListData);
      });
      return;
    } else {
      setModState(() {
        ModInfos.clear();
        ModInfos.addAll(AllModInfos);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
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
        FutureBuilder(
            future: GetModInfos(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return StatefulBuilder(builder: (context, setModState_) {
                  setModState = setModState_;
                  // context = context;
                  return ListView.builder(
                      cacheExtent: 0.5,
                      controller: ScrollController(),
                      shrinkWrap: true,
                      itemCount: ModInfos.length,
                      itemBuilder: (context, index) {
                        try {
                          return ModListTile(
                              ModInfos[index],
                              ModInfos[index].name,
                              ModInfos[index].file,
                              context);
                        } catch (err) {
                          return Container();
                        }
                      });
                });
              } else {
                return Center(child: CircularProgressIndicator());
              }
            })
      ],
    );
  }

  Widget ModListTile(
      ModInfo modInfo, String ModName, File ModFile, BuildContext context) {
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
          Builder(
            builder: (context) {
              if (modInfo.loader == instanceConfig["loader"]) {
                return Container();
              } else {
                return Positioned(
                  top: 7,
                  left: 7,
                  child: Tooltip(
                    child: Icon(Icons.warning),
                    message:
                        "This mod is a ${modInfo.loader} mod, this is a ${instanceConfig["loader"]} instance",
                  ),
                );
              }
            },
          ),
          Text(ModName),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(builder: (content) {
            int CurseID = modInfo.curseID;
            if (CurseID != 0) {
              return IconButton(
                onPressed: () async {
                  Response response = await get(
                      Uri.parse("${CurseForgeModAPI}/addon/${CurseID}"));
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
          }),
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
                        modInfo.description),
                    Text(i18n.Format("edit.instance.mods.list.version") +
                        modInfo.version.toString()),
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
