import 'dart:convert';
import 'dart:io';

import 'package:contextmenu/contextmenu.dart';
import 'package:rpmlauncher/Function/Counter.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Model/IsolatesOption.dart';
import 'package:rpmlauncher/Model/ModInfo.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/main.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';

import '../Widget/FileSwitchBox.dart';
import '../Widget/RWLLoading.dart';

class ModListView extends StatelessWidget {
  final TextEditingController modSearchController = TextEditingController();
  final List<FileSystemEntity> files;
  final InstanceConfig instanceConfig;
  static late File modIndexFile;
  static late Map modIndex;
  static late StateSetter setModState;
  static List<ModInfo> modInfos = [];
  static List<ModInfo> allModInfos = [];

  ModListView(this.files, this.instanceConfig) {
    modIndexFile = File(join(dataHome.absolute.path, "mod_index.json"));
    if (!modIndexFile.existsSync()) {
      modIndexFile.writeAsStringSync("{}");
    }
    modIndex = json.decode(modIndexFile.readAsStringSync());
  }

  static ModInfo getModInfo(File modFile, String modHash, Map _modIndex,
      File _modIndexFile, IsolatesOption option) {
    Logger _logger = option.counter.logger;
    Directory _dataHome = option.counter.dataHome;
    final unzipped =
        ZipDecoder().decodeBytes(File(modFile.absolute.path).readAsBytesSync());
    ModLoaders modType = ModLoaders.unknown;
    Map conflict = {};
    Map modInfoMap = {};
    for (final file in unzipped) {
      final filename = file.name;
      if (file.isFile) {
        if (filename == "fabric.mod.json") {
          final data = file.content as List<int>;
          modType = ModLoaders.fabric;
          //Fabric Mod Info File
          try {
            modInfoMap =
                json.decode(Utf8Decoder(allowMalformed: true).convert(data));
          } catch (e) {
            _logger.send("About line 97: " + e.toString());
            var modInfo = ModInfo(
                loader: modType,
                name: modFile.absolute.path
                    .split(Platform.pathSeparator)
                    .last
                    .replaceFirst(".jar", "")
                    .replaceFirst(".disable", ""),
                description: 'unknown',
                version: 'unknown',
                curseID: null,
                filePath: modFile.path,
                id: "unknown");
            _modIndex[modHash] = modInfo.toList();
            _modIndexFile.writeAsStringSync(json.encode(_modIndex));
            return modInfo;
          }
          try {
            if (modInfoMap.containsKey("icon")) {
              for (var i in unzipped) {
                if (i.name == modInfoMap["icon"]) {
                  File(join(
                      _dataHome.absolute.path, "ModTempIcons", "$modHash.png"))
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(i.content as List<int>);
                }
              }
            }
          } catch (err) {
            _logger.send("Mod Icon Parsing Error $err");
          }
          if (modInfoMap.containsKey("conflicts")) {
            conflict.addAll(modInfoMap["conflicts"] ?? {});
          }
          if (modInfoMap.containsKey("breaks")) {
            conflict.addAll(modInfoMap["breaks"] ?? {});
          }
          var modInfo = ModInfo(
              loader: modType,
              name: modInfoMap["name"],
              description: modInfoMap["description"],
              version: modInfoMap["version"],
              curseID: null,
              filePath: modFile.path,
              conflicts: ConflictMods.fromMap(conflict),
              id: modInfoMap["id"]);
          _modIndex[modHash] = modInfo.toList();
          _modIndexFile.writeAsStringSync(json.encode(_modIndex));
          return modInfo;
        } else if (filename.contains("META-INF/mods.toml")) {
          //Forge Mod Info File (1.13 -> 1.17.1+)
          final data = file.content as List<int>;
          modType = ModLoaders.forge;
          TomlDocument modToml;
          try {
            modToml = TomlDocument.parse(
                Utf8Decoder(allowMalformed: true).convert(data));
          } catch (e, stackTrace) {
            _logger.error(ErrorType.io, e, stackTrace: stackTrace);
            var modInfo = ModInfo(
                loader: modType,
                name: modFile.absolute.path
                    .split(Platform.pathSeparator)
                    .last
                    .replaceFirst(".jar", "")
                    .replaceFirst(".disable", ""),
                description: 'unknown',
                version: 'unknown',
                curseID: null,
                filePath: modFile.path,
                id: "unknown");
            _modIndex[modHash] = modInfo.toList();
            _modIndexFile.writeAsStringSync(json.encode(_modIndex));
            return modInfo;
          }

          modInfoMap = modToml.toMap();

          final Map info = modInfoMap["mods"][0];

          if (modInfoMap["logoFile"].toString().isNotEmpty) {
            for (var i in unzipped) {
              if (i.name == modInfoMap["logoFile"]) {
                File(join(
                    _dataHome.absolute.path, "ModTempIcons", "$modHash.png"))
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(i.content as List<int>);
              }
            }
          }

          var modInfo = ModInfo(
              loader: modType,
              name: info["displayName"],
              description: info["description"],
              version: info["version"],
              curseID: null,
              filePath: modFile.path,
              id: info["modId"]);
          _modIndex[modHash] = modInfo.toList();
          _modIndexFile.writeAsStringSync(json.encode(_modIndex));
          return modInfo;
        } else if (filename == "mcmod.info") {
          final data = file.content as List<int>;
          modType = ModLoaders.forge;
          //Forge Mod Info File (1.7.10 -> 1.12.2)
          modInfoMap =
              json.decode(Utf8Decoder(allowMalformed: true).convert(data))[0];

          if (modInfoMap["logoFile"].toString().isNotEmpty) {
            for (var i in unzipped) {
              if (i.name == modInfoMap["logoFile"]) {
                File(join(
                    _dataHome.absolute.path, "ModTempIcons", "$modHash.png"))
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(i.content as List<int>);
              }
            }
          }

          var modInfo = ModInfo(
              loader: modType,
              name: modInfoMap["name"],
              description: modInfoMap["description"],
              version: modInfoMap["version"],
              curseID: null,
              filePath: modFile.path,
              id: modInfoMap["modid"]);
          _modIndex[modHash] = modInfo.toList();
          _modIndexFile.writeAsStringSync(json.encode(_modIndex));
          return modInfo;
        }
      }
    }

    var modInfo = ModInfo(
        loader: ModLoaders.unknown,
        name: modFile.absolute.path
            .split(Platform.pathSeparator)
            .last
            .replaceFirst(".jar", "")
            .replaceFirst(".disable", ""),
        description: 'unknown',
        version: 'unknown',
        curseID: null,
        filePath: modFile.path,
        id: 'unknown');
    _modIndex[modHash] = modInfo.toList();
    _modIndexFile.writeAsStringSync(json.encode(_modIndex));

    return modInfo;
  }

  static List<ModInfo> getModInfos(IsolatesOption option) {
    List args = option.args;
    List<FileSystemEntity> files = args[0];
    File modIndexFile = args[1];
    Map modIndex = json.decode(modIndexFile.readAsStringSync());
    Directory _dataHome = option.counter.dataHome;
    Logger _logger = Logger(_dataHome);
    allModInfos.clear();
    try {
      for (FileSystemEntity file in files) {
        File modFile = File(file.path);

        if (!modFile.existsSync()) continue;

        final modHash = Uttily.murmurhash2(modFile).toString();
        if (modIndex.containsKey(modHash)) {
          List infoList = modIndex[modHash];
          infoList.add(modFile.path);
          ModInfo modInfo = ModInfo.fromList(infoList);
          allModInfos.add(modInfo);
        } else {
          try {
            ModInfo _ =
                getModInfo(modFile, modHash, modIndex, modIndexFile, option);
            List infoList = (_).toList();
            infoList.add(modFile.path);
            ModInfo modInfo = ModInfo.fromList(infoList);
            allModInfos.add(modInfo);
          } on FormatException catch (e, stackTrace) {
            if (e is! ArchiveException) {
              _logger.error(ErrorType.io, e, stackTrace: stackTrace);
            }
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.error(ErrorType.io, e, stackTrace: stackTrace);
    }
    return allModInfos;
  }

  void filterSearchResults(String query) {
    modInfos = allModInfos.where((modInfo) {
      String name = modInfo.name;
      final nameLower = name.toLowerCase();
      final searchLower = query.toLowerCase();
      return nameLower.contains(searchLower);
    }).toList();
    setModState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      controller: ScrollController(),
      children: [
        SizedBox(
          height: 12,
        ),
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
              controller: modSearchController,
              decoration: InputDecoration(
                hintText: "請輸入模組名稱...",
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white12, width: 3.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue, width: 3.0),
                ),
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              onEditingComplete: () {
                filterSearchResults(modSearchController.text);
              },
            )),
            SizedBox(
              width: 12,
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
                getModInfos,
                IsolatesOption(Counter.of(context),
                    args: [files, modIndexFile])),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                (snapshot.data as List<ModInfo>).sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                allModInfos = snapshot.data;
                modInfos = allModInfos;
                return StatefulBuilder(builder: (context, setModState_) {
                  setModState = setModState_;
                  return ListView.builder(
                      cacheExtent: 0.5,
                      controller: ScrollController(),
                      shrinkWrap: true,
                      itemCount: modInfos.length,
                      itemBuilder: (context, index) {
                        try {
                          return modListTile(
                              modInfos[index], context, modInfos);
                        } catch (error, stackTrace) {
                          logger.error(ErrorType.unknown, error,
                              stackTrace: stackTrace);
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

  Widget modListTile(ModInfo modInfo, BuildContext context, List modList) {
    File modFile = File(modInfo.filePath);

    if (!modFile.existsSync()) {
      if (extension(modFile.path) == '.jar' &&
              File(modFile.path + ".disable").existsSync() ||
          (extension(modFile.path) == '.disable' &&
              File(modFile.path.split(".disable")[0]).existsSync())) {
      } else {
        return SizedBox();
      }
    }

    String modName = modInfo.name;
    final String modHash = Uttily.murmurhash2(modFile).toString();
    File imageFile =
        File(join(dataHome.absolute.path, "ModTempIcons", "$modHash.png"));
    late Widget image;
    if (imageFile.existsSync()) {
      image = Image.file(imageFile, fit: BoxFit.fill);
    } else {
      image = Icon(Icons.image, size: 50);
    }

    return ContextMenuArea(
      items: [
        ListTile(
          title: I18nText("edit.instance.mods.list.delete"),
          subtitle: I18nText("edit.instance.mods.list.delete.description"),
          onTap: () {
            navigator.pop();
            modInfo.delete();
          },
        ),
        Builder(builder: (context) {
          bool modSwitch = !modInfo.file.path.endsWith(".disable");

          String tooltip = modSwitch
              ? I18n.format('gui.disable')
              : I18n.format('gui.enable');
          return ListTile(
            title: Text(tooltip),
            subtitle: Text("$tooltip您選取的模組"),
            onTap: () {
              if (modSwitch) {
                modSwitch = false;
                String name = modInfo.file.absolute.path + ".disable";
                modInfo.file.rename(name);
                modInfo.file = File(name);
                setModState(() {});
              } else {
                modSwitch = true;
                String name = modInfo.file.absolute.path.split(".disable")[0];
                modInfo.file.rename(name);
                modInfo.file = File(name);
                setModState(() {});
              }
              navigator.pop();
            },
          );
        }),
      ],
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              leading: SizedBox(child: image, width: 50, height: 50),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(modName),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(builder: (context) {
                    List<ModInfo> conflictMods = allModInfos
                        .where((_modInfo) => _modInfo.conflicts == null
                            ? false
                            : _modInfo.conflicts!.isConflict(modInfo))
                        .toList();
                    if (conflictMods.isNotEmpty) {
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
                      if (modInfo.loader == instanceConfig.loaderEnum) {
                        return SizedBox();
                      } else {
                        return Tooltip(
                          child: Icon(Icons.warning),
                          message:
                              "此模組的模組載入器是 ${modInfo.loader.fixedString}，與此安裝檔 ${instanceConfig.loader} 的模組載入器不相符。",
                        );
                      }
                    },
                  ),
                  FileSwitchBox(file: modFile),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      modInfo.delete();
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
                            I18n.format("edit.instance.mods.list.name") +
                                modName,
                            textAlign: TextAlign.center),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(I18n.format(
                                    "edit.instance.mods.list.description") +
                                (modInfo.description ?? "")),
                            Text(
                                I18n.format("edit.instance.mods.list.version") +
                                    modInfo.version.toString()),
                            Builder(builder: (content) {
                              int? curseID = modInfo.curseID;
                              if (curseID == null) {
                                return FutureBuilder(
                                    future: CurseForgeHandler.checkFingerPrint(
                                        modFile),
                                    builder: (content, AsyncSnapshot snapshot) {
                                      if (snapshot.hasData) {
                                        curseID = snapshot.data;
                                        modInfo.curseID = curseID;
                                        modIndex[modHash] = modInfo.toList();
                                        modIndexFile.writeAsStringSync(
                                            json.encode(modIndex));
                                        return curseForgeInfo(curseID ?? 0);
                                      } else {
                                        return RWLLoading();
                                      }
                                    });
                              } else {
                                return curseForgeInfo(curseID);
                              }
                            }),
                          ],
                        ));
                  },
                );
              },
            ),
          ),
          SizedBox(
            width: 15,
          ),
        ],
      ),
    );
  }
}

Widget curseForgeInfo(int curseID) {
  return Builder(builder: (content) {
    if (curseID != 0) {
      return IconButton(
        onPressed: () async {
          Response response =
              await get(Uri.parse("$curseForgeModAPI/addon/$curseID"));
          String pageUrl = json.decode(response.body)["websiteUrl"];
          Uttily.openUrl(pageUrl);
        },
        icon: Icon(Icons.open_in_new),
        tooltip: "在 CurseForge 中檢視此模組",
      );
    } else {
      return SizedBox.shrink();
    }
  });
}
