import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:rpmlauncher/Function/Counter.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/IO/IsolatesOption.dart';
import 'package:rpmlauncher/Model/Game/ModInfo.dart';
import 'package:rpmlauncher/Utility/Logger.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:toml/toml.dart';

import '../../Widget/FileSwitchBox.dart';
import '../../Widget/RWLLoading.dart';

class ModListView extends StatefulWidget {
  final Instance instance;
  InstanceConfig get instanceConfig => instance.config;

  const ModListView(this.instance);

  @override
  State<ModListView> createState() => _ModListViewState();
}

class _ModListViewState extends State<ModListView> {
  final TextEditingController modSearchController = TextEditingController();
  StateSetter? setModState;
  late StreamSubscription<FileSystemEvent> modDirEvent;
  late List<FileSystemEntity> files;
  Directory get modDir =>
      InstanceRepository.getModRootDir(widget.instance.uuid);

  late File modIndexFile;
  late Map modIndex;
  late ReceivePort progressPort;
  late SendPort progressSendPort;
  late List<ModInfo> modInfos;
  List<ModInfo>? allModInfos;

  List<String> deletedModFiles = [];

  @override
  void initState() {
    modIndexFile = GameRepository.getModInsdexFile();
    if (!modIndexFile.existsSync()) {
      modIndexFile.writeAsStringSync("{}");
    }
    modIndex = json.decode(modIndexFile.readAsStringSync());
    files = widget.instance.getModFiles();
    progressPort = ReceivePort();
    progressSendPort = progressPort.sendPort;

    super.initState();

    modDirEvent = modDir.watch().listen((event) {
      if (!modDir.existsSync()) modDirEvent.cancel();
      if (event is FileSystemMoveEvent) {
        return;
      }
      files = widget.instance.getModFiles();
      if (deletedModFiles.contains(event.path) && mounted) {
        deletedModFiles.remove(event.path);
        return;
      } else if (mounted) {
        try {
          setState(() {});
        } catch (e) {}
      }
    });
  }

  @override
  void dispose() {
    modDirEvent.cancel();
    modSearchController.dispose();
    super.dispose();
  }

  static ModInfo getModInfo(
      File modFile, String modHash, IsolatesOption option) {
    Logger _logger = option.counter.logger;
    Directory _dataHome = option.counter.dataHome;
    ModLoader modType = ModLoader.unknown;
    try {
      final unzipped = ZipDecoder()
          .decodeBytes(File(modFile.absolute.path).readAsBytesSync());
      Map conflict = {};
      Map modInfoMap = {};

      ArchiveFile? fabric = unzipped.findFile('fabric.mod.json');

      //Forge Mod Info File (1.13 -> 1.17.1+)
      ArchiveFile? forge113 = unzipped.findFile('META-INF/mods.toml');

      //Forge Mod Info File (1.7.10 -> 1.12.2)
      ArchiveFile? forge112 = unzipped.findFile('mcmod.info');

      if (fabric != null) {
        modType = ModLoader.fabric;
        //Fabric Mod Info File
        modInfoMap = json.decode(utf8.decode(fabric.content as List<int>));

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
        ModInfo modInfo = ModInfo(
            loader: modType,
            name: modInfoMap["name"],
            description: modInfoMap["description"],
            version: modInfoMap["version"],
            curseID: null,
            filePath: modFile.path,
            conflicts: ConflictMods.fromMap(conflict),
            id: modInfoMap["id"]);
        return modInfo;
      } else if (forge113 != null) {
        modType = ModLoader.forge;
        TomlDocument modToml;

        modToml = TomlDocument.parse(Utf8Decoder(allowMalformed: true)
            .convert(forge113.content as List<int>));

        modInfoMap = modToml.toMap();

        final Map info = modInfoMap["mods"][0];

        if (modInfoMap["logoFile"].toString().isNotEmpty) {
          for (var i in unzipped) {
            if (i.name == modInfoMap["logoFile"]) {
              File(
                  join(_dataHome.absolute.path, "ModTempIcons", "$modHash.png"))
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
        return modInfo;
      } else if (forge112 != null) {
        modType = ModLoader.forge;
        modInfoMap = json.decode(Utf8Decoder(allowMalformed: true)
            .convert(forge112.content as List<int>))[0];

        if (modInfoMap["logoFile"].toString().isNotEmpty) {
          for (ArchiveFile f in unzipped) {
            if (f.name == modInfoMap["logoFile"]) {
              File(
                  join(_dataHome.absolute.path, "ModTempIcons", "$modHash.png"))
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
        return modInfo;
      } else {
        throw Exception("Unknown ModLoader");
      }
    } catch (e) {
      ModInfo modInfo = ModInfo(
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
      return modInfo;
    }
  }

  static Future<List<ModInfo>> getModInfos(IsolatesOption option) async {
    DateTime start = DateTime.now();
    List<ModInfo> _modInfos = [];
    List args = option.args;
    List<FileSystemEntity> files = args[0];
    File modIndexFile = args[1];
    SendPort _progressSendPort = args[2];
    Map modIndex = json.decode(modIndexFile.readAsStringSync());
    Logger _logger = Logger(option.counter.dataHome);
    try {
      for (FileSystemEntity modFile in files) {
        if (modFile is File) {
          if (!modFile.existsSync()) continue;

          int modHash = Uttily.murmurhash2(modFile);
          if (modIndex.containsKey(modHash.toString())) {
            ModInfo modInfo =
                ModInfo.fromMap(modIndex[modHash.toString()], modFile);
            modInfo.modHash = modHash;
            _modInfos.add(modInfo);
          } else {
            try {
              ModInfo modInfo = getModInfo(modFile, modHash.toString(), option);
              int? curseID = await CurseForgeHandler.checkFingerPrint(modHash);
              modInfo.curseID = curseID;
              modInfo.file = modFile;
              modInfo.modHash = modHash;
              modIndex[modHash.toString()] = modInfo.toMap();
              _modInfos.add(modInfo);
            } on FormatException catch (e, stackTrace) {
              if (e is! ArchiveException) {
                _logger.error(ErrorType.io, e, stackTrace: stackTrace);
              }
            }
          }
        }
        _progressSendPort.send((files.indexOf(modFile) + 1) / files.length);
      }
    } catch (e, stackTrace) {
      _logger.error(ErrorType.io, e, stackTrace: stackTrace);
    }

    modIndexFile.writeAsStringSync(json.encode(modIndex));

    _modInfos
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    DateTime end = DateTime.now();
    _logger
        .info("ModInfos loaded in ${end.difference(start).inMilliseconds}ms");
    return _modInfos;
  }

  void filterSearchResults(String query) {
    if (allModInfos != null) {
      modInfos = allModInfos!.where((modInfo) {
        String name = modInfo.name;
        final nameLower = name.toLowerCase();
        final searchLower = query.toLowerCase();
        return nameLower.contains(searchLower);
      }).toList();
    }

    setModState?.call(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Center(
          child: Text(
        I18n.format("edit.instance.mods.list.found"),
        style: TextStyle(fontSize: 30),
      ));
    } else {
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
                  getModInfos,
                  IsolatesOption(Counter.of(context),
                      args: [files, modIndexFile, progressSendPort])),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  allModInfos = snapshot.data;
                  modInfos = allModInfos!;
                  return StatefulBuilder(builder: (context, setModState_) {
                    DateTime start = DateTime.now();
                    setModState = setModState_;
                    return ListView.builder(
                        shrinkWrap: true,
                        cacheExtent: 1,
                        controller: ScrollController(),
                        itemCount: modInfos.length,
                        itemBuilder: (context, index) {
                          final item = modInfos[index];

                          try {
                            return Dismissible(
                              key: Key(item.filePath),
                              onDismissed: (direction) async {
                                bool deleted = await item.delete();

                                if (deleted) {
                                  setModState_(() {
                                    modInfos.removeAt(index);
                                  });

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          content: I18nText(
                                    'edit.instance.mods.deleted',
                                    args: {"mod_name": item.name},
                                  )));
                                }
                              },
                              background: Container(color: Colors.red),
                              child: modListTile(item, context, index),
                            );
                          } catch (error, stackTrace) {
                            logger.error(ErrorType.unknown, error,
                                stackTrace: stackTrace);
                            return Container();
                          } finally {
                            if (index == modInfos.length - 1) {
                              DateTime end = DateTime.now();
                              logger.info(
                                  "ModList built in ${end.difference(start).inMilliseconds}ms");
                            }
                          }
                        });
                  });
                } else if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                } else {
                  return _ModInfoLoading(progressPort: progressPort);
                }
              }),
        ],
      );
    }
  }

  Widget modListTile(ModInfo modInfo, BuildContext context, int index) {
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
    String modHash = modInfo.modHash.toString();

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
            modInfo.delete(
              onDeleting: () {
                deletedModFiles.add(modInfo.filePath);
                modInfos.removeAt(index);
                setModState?.call(() {});
              },
            );
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
            onTap: () async {
              try {
                if (modSwitch) {
                  modSwitch = false;
                  String name = modInfo.file.absolute.path + ".disable";
                  await modInfo.file.rename(name);
                  modInfo.file = File(name);
                  setModState?.call(() {});
                } else {
                  modSwitch = true;
                  String name = modInfo.file.absolute.path.split(".disable")[0];
                  await modInfo.file.rename(name);
                  modInfo.file = File(name);
                  setModState?.call(() {});
                }
              } on FileSystemException {}
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
                    List<ModInfo> conflictMods = allModInfos!
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
                      if (modInfo.loader == widget.instanceConfig.loaderEnum ||
                          modInfo.loader == ModLoader.unknown) {
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
                      modInfo.delete(onDeleting: () {
                        deletedModFiles.add(modInfo.filePath);
                        modInfos.removeAt(index);
                        setModState?.call(() {});
                      });
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
                                        int.parse(modHash)),
                                    builder: (content, AsyncSnapshot snapshot) {
                                      if (snapshot.hasData) {
                                        curseID = snapshot.data;
                                        modInfo.curseID = curseID;
                                        modIndex[modHash] = modInfo.toMap();
                                        modIndexFile.writeAsStringSync(
                                            json.encode(modIndex));
                                        return curseForgeInfo(curseID);
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

class _ModInfoLoading extends StatefulWidget {
  const _ModInfoLoading({
    Key? key,
    required this.progressPort,
  }) : super(key: key);

  final ReceivePort progressPort;

  @override
  State<_ModInfoLoading> createState() => _ModInfoLoadingState();
}

class _ModInfoLoadingState extends State<_ModInfoLoading> {
  double progress = 0.0;

  @override
  void initState() {
    super.initState();

    widget.progressPort.listen((message) {
      if (message is double) {
        progress = message;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 30),
        Row(
          children: [
            SizedBox(
              width: 50,
            ),
            Expanded(child: LinearProgressIndicator(value: progress)),
            SizedBox(
              width: 50,
            ),
          ],
        ),
      ],
    );
  }
}

Widget curseForgeInfo(int? curseID) {
  return Builder(builder: (content) {
    if (curseID != null) {
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
