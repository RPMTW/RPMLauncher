import 'dart:convert';
import 'dart:io';

import 'package:contextmenu/contextmenu.dart';
import 'package:rpmlauncher/Function/Counter.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/IO/IsolatesOption.dart';
import 'package:rpmlauncher/Model/Game/ModInfo.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:rpmlauncher/main.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';

import '../Widget/FileSwitchBox.dart';
import '../Widget/RWLLoading.dart';

class ModListView extends StatefulWidget {
  final List<FileSystemEntity> files;

  final InstanceConfig instanceConfig;
  late File modIndexFile;
  late Map modIndex;
  List<ModInfo> modInfos = [];
  List<ModInfo> allModInfos = [];

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
            _logger.error(ErrorType.modInfoParse, e);
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

          ModInfo modInfo = ModInfo(
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
            for (ArchiveFile f in unzipped) {
              if (f.name == modInfoMap["logoFile"]) {
                File(join(
                    _dataHome.absolute.path, "ModTempIcons", "$modHash.png"))
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(f.content as List<int>);
              }
            }
          }

          ModInfo modInfo = ModInfo(
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

    ModInfo modInfo = ModInfo(
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
    List<ModInfo> _modInfos = [];
    List args = option.args;
    List<FileSystemEntity> files = args[0];
    File modIndexFile = args[1];
    Map modIndex = json.decode(modIndexFile.readAsStringSync());
    Logger _logger = Logger(option.counter.dataHome);
    try {
      for (FileSystemEntity file in files) {
        File modFile = File(file.path);

        if (!modFile.existsSync()) continue;

        final modHash = Uttily.murmurhash2(modFile).toString();
        if (modIndex.containsKey(modHash)) {
          List infoList = modIndex[modHash];
          infoList.add(modFile.path);
          ModInfo modInfo = ModInfo.fromList(infoList);
          _modInfos.add(modInfo);
        } else {
          try {
            ModInfo _ =
                getModInfo(modFile, modHash, modIndex, modIndexFile, option);
            List infoList = (_).toList();
            infoList.add(modFile.path);
            ModInfo modInfo = ModInfo.fromList(infoList);
            _modInfos.add(modInfo);
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
    _modInfos
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return _modInfos;
  }

  @override
  State<ModListView> createState() => _ModListViewState();
}

class _ModListViewState extends State<ModListView> {
  final TextEditingController modSearchController = TextEditingController();
  late StateSetter setModState;

  void filterSearchResults(String query) {
    widget.modInfos = widget.allModInfos.where((modInfo) {
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
                child: RPMTextField(
              textAlign: TextAlign.center,
              controller: modSearchController,
              hintText: I18n.format('edit.instance.mods.enter'),
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
                ModListView.getModInfos,
                IsolatesOption(Counter.of(context),
                    args: [widget.files, widget.modIndexFile])),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                widget.allModInfos = snapshot.data;
                widget.modInfos = widget.allModInfos;
                return StatefulBuilder(builder: (context, setModState_) {
                  setModState = setModState_;
                  return ListView.builder(
                      cacheExtent: 1,
                      controller: ScrollController(),
                      shrinkWrap: true,
                      itemCount: widget.modInfos.length,
                      itemBuilder: (context, index) {
                        final item = widget.modInfos[index];

                        try {
                          return Dismissible(
                            key: Key(item.name),
                            onDismissed: (direction) {
                              setModState_(() {
                                widget.modInfos.removeAt(index);
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('${item.name} dismissed')));
                            },
                            background: Container(color: Colors.red),
                            child: modListTile(item, context, widget.modInfos),
                          );
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
            subtitle: I18nText(
              "edit.instance.mods.list.disable_or_enable",
              args: {"disable_or_enable": tooltip},
            ),
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
                    List<ModInfo> conflictMods = widget.allModInfos
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
                        message: I18n.format('edit.instance.mods.list.conflict',
                            args: {
                              "mods": conflictModNames
                                  .join(I18n.format('gui.separate'))
                            }),
                        child: Icon(Icons.warning),
                      );
                    }
                    return SizedBox();
                  }),
                  Builder(
                    builder: (context) {
                      if (modInfo.loader == widget.instanceConfig.loaderEnum) {
                        return SizedBox();
                      } else {
                        return Tooltip(
                            child: Icon(Icons.warning),
                            message: I18n.format(
                                "edit.instance.mods.list.conflict.loader",
                                args: {
                                  "modloader": modInfo.loader.fixedString,
                                  "instance_modloader":
                                      widget.instanceConfig.loader
                                }));
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
                                        widget.modIndex[modHash] =
                                            modInfo.toList();
                                        widget.modIndexFile.writeAsStringSync(
                                            json.encode(widget.modIndex));
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
          Uttily.openUri(pageUrl);
        },
        icon: Icon(Icons.open_in_new),
        tooltip: I18n.format('edit.instance.mods.open_in_curseforge'),
      );
    } else {
      return SizedBox.shrink();
    }
  });
}
