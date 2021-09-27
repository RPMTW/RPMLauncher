// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Model/ModInfo.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/main.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';

import 'FileSwitchBox.dart';
import 'RWLLoading.dart';

class ModListView extends StatelessWidget {
  late List<FileSystemEntity> files;
  late TextEditingController ModSearchController;
  late Map instanceConfig;
  late String InstanceDirName;
  static late File ModIndex_;
  static late Map ModIndex;
  static List<ModInfo> ModInfos = [];
  static List<ModInfo> AllModInfos = [];
  late var setModState;

  ModListView(List<FileSystemEntity> files_, ModSearchController_,
      instanceConfig_, String InstanceDirName_) {
    files = files_;
    ModSearchController = ModSearchController_;
    instanceConfig = instanceConfig_;
    InstanceDirName = InstanceDirName_;

    ModIndex_ = File(join(dataHome.absolute.path, "mod_index.json"));
    if (!ModIndex_.existsSync()) {
      ModIndex_.writeAsStringSync("{}");
    }
    ModIndex = json.decode(ModIndex_.readAsStringSync());
  }

  static ModInfo GetModInfo(File ModFile, String ModHash, Map ModIndex,
      File ModIndex_, Directory _dataHome, Logger _logger) {
    final unzipped =
        ZipDecoder().decodeBytes(File(ModFile.absolute.path).readAsBytesSync());
    ModLoaders ModType = ModLoaders.Unknown;
    Map conflict = {};
    Map ModInfoMap = {};
    for (final file in unzipped) {
      final filename = file.name;
      if (file.isFile) {
        if (filename == "fabric.mod.json") {
          final data = file.content as List<int>;
          ModType = ModLoaders.Fabric;
          //Fabric Mod Info File
          try {
            ModInfoMap =
                json.decode(Utf8Decoder(allowMalformed: true).convert(data));
          } catch (e) {
            _logger.send("About line 97: " + e.toString());
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
                      _dataHome.absolute.path, "ModTempIcons", "$ModHash.png"))
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(i.content as List<int>);
                }
              }
            }
          } catch (err) {
            _logger.send("Mod Icon Parsing Error $err");
          }
          if (ModInfoMap.containsKey("conflicts")) {
            conflict.addAll(ModInfoMap["conflicts"] ?? {});
          }
          if (ModInfoMap.containsKey("breaks")) {
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
          return modInfo;
        } else if (filename.contains("META-INF/mods.toml")) {
          //Forge Mod Info File (1.13 -> 1.17.1+)
          final data = file.content as List<int>;
          ModType = ModLoaders.Forge;
          TomlDocument ModToml;
          try {
            ModToml = TomlDocument.parse(
                Utf8Decoder(allowMalformed: true).convert(data));
          } catch (e) {
            _logger.send("About line 162: " + e.toString());
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
                    _dataHome.absolute.path, "ModTempIcons", "$ModHash.png"))
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
          ModType = ModLoaders.Forge;
          //Forge Mod Info File (1.7.10 -> 1.12.2)
          ModInfoMap =
              json.decode(Utf8Decoder(allowMalformed: true).convert(data))[0];

          if (ModInfoMap["logoFile"].toString().isNotEmpty) {
            for (var i in unzipped) {
              if (i.name == ModInfoMap["logoFile"]) {
                File(join(
                    _dataHome.absolute.path, "ModTempIcons", "$ModHash.png"))
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
        loader: ModLoaders.Unknown,
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
    Directory _dataHome = args[3];
    Logger _logger = Logger(_dataHome);
    AllModInfos.clear();
    try {
      for (FileSystemEntity file in files) {
        File ModFile = File(file.path);

        if (!ModFile.existsSync()) continue;

        final ModHash = utility.murmurhash2(ModFile).toString();
        if (ModIndex.containsKey(ModHash)) {
          List infoList = ModIndex[ModHash];

          infoList.add(ModFile.path);
          ModInfo modInfo = ModInfo.fromList(infoList);
          AllModInfos.add(modInfo);
        } else {
          List infoList = (GetModInfo(
                  ModFile, ModHash, ModIndex, ModIndex_, _dataHome, _logger))
              .toList();
          infoList.add(ModFile.path);
          ModInfo modInfo = ModInfo.fromList(infoList);
          AllModInfos.add(modInfo);
        }
      }
    } catch (e) {
      _logger.error(ErrorType.IO, e);
    }
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
              child: Text(i18n.format("gui.search")),
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
            future:
                compute(GetModInfos, [files, ModIndex, ModIndex_, dataHome]),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
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
                          return ModListTile(
                              ModInfos[index], context, ModInfos);
                        } catch (error) {
                          logger.send("About line 376: " + error.toString());
                          return Container();
                        }
                      });
                });
              } else if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              } else {
                return Column(
                  children: [
                    SizedBox(height: 20),
                    RWLLoading(),
                  ],
                );
              }
            }),
      ],
    );
  }

  Widget ModListTile(ModInfo modInfo, BuildContext context, List ModList) {
    File ModFile = File(modInfo.file);

    if (!ModFile.existsSync()) {
      if (extension(ModFile.path) == '.jar' &&
              File(ModFile.path + ".disable").existsSync() ||
          (extension(ModFile.path) == '.disable' &&
              File(ModFile.path.split(".disable")[0]).existsSync())) {
      } else {
        return SizedBox();
      }
    }

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
          Text(ModName),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(builder: (context) {
            List<ModInfo> conflictMods = AllModInfos.where(
                    (_modInfo) => _modInfo.conflicts.containsKey(modInfo.id))
                .toList();
            if (conflictMods.length > 0) {
              List<String> conflictModNames = [];
              conflictMods.forEach((mod) {
                conflictModNames.add(mod.name);
              });
              return Tooltip(
                message: "這個模組與 ${conflictModNames.join("、")} 衝突",
                child: Icon(Icons.warning),
              );
            }
            return SizedBox();
          }),
          Builder(
            builder: (context) {
              if (modInfo.loader == instanceConfig["loader"]) {
                return SizedBox();
              } else {
                return Tooltip(
                  child: Icon(Icons.warning),
                  message:
                      "此模組的模組載入器是 ${modInfo.loader}，與此安裝檔 ${instanceConfig["loader"]} 的模組載入器不相符。",
                );
              }
            },
          ),
          FileSwitchBox(file: ModFile),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(i18n.format("gui.tips.info")),
                    content: Text("您確定要刪除此模組嗎？ (此動作將無法復原)"),
                    actions: [
                      TextButton(
                        child: Text(i18n.format("gui.cancel")),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                          child: Text(i18n.format("gui.confirm")),
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
                    i18n.format("edit.instance.mods.list.name") + ModName,
                    textAlign: TextAlign.center),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(i18n.format("edit.instance.mods.list.description") +
                        (modInfo.description ?? "")),
                    Text(i18n.format("edit.instance.mods.list.version") +
                        modInfo.version.toString()),
                    Builder(builder: (content) {
                      int? CurseID = modInfo.curseID;
                      if (CurseID == null) {
                        return FutureBuilder(
                            future: CurseForgeHandler.CheckFingerPrint(ModFile),
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
                                return RWLLoading();
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
}

Widget CurseForgeInfo(int CurseID) {
  return Builder(builder: (content) {
    if (CurseID != 0) {
      return IconButton(
        onPressed: () async {
          Response response =
              await get(Uri.parse("${CurseForgeModAPI}/addon/${CurseID}"));
          String PageUrl = json.decode(response.body)["websiteUrl"];
          utility.OpenUrl(PageUrl);
        },
        icon: Icon(Icons.open_in_new),
        tooltip: "在 CurseForge 中檢視此模組",
      );
    } else {
      return Container();
    }
  });
}
