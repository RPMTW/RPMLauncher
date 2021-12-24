import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:rpmlauncher/Function/Counter.dart';
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
import 'package:rpmlauncher/View/OptionsView.dart';
import 'package:rpmlauncher/Widget/ModSourceSelection.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  late List<ModInfo> modInfos;
  List<ModInfo>? allModInfos;

  List<String> deletedModFiles = [];

  @override
  void initState() {
    modIndexFile = GameRepository.getModInsdexFile();
    if (!modIndexFile.existsSync()) {
      modIndexFile.createSync(recursive: true);
      modIndexFile.writeAsStringSync("{}");
    }
    modIndex = json.decode(modIndexFile.readAsStringSync());
    files = widget.instance.getModFiles();

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
    ReceivePort progressPort = ReceivePort();
    return FutureBuilder(
        future: compute(
            getModInfos,
            IsolatesOption(Counter.of(context),
                args: [files, modIndexFile, progressPort.sendPort])),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            allModInfos = snapshot.data;
            modInfos = allModInfos!;

            return OptionPage(
              mainWidget: Builder(builder: (context) {
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
                      StatefulBuilder(builder: (context, setModState_) {
                        DateTime start = DateTime.now();
                        setModState = setModState_;
                        return SingleChildScrollView(
                          controller: ScrollController(),
                          child: ListBody(
                            children: modInfos.map((item) {
                              int index = modInfos.indexOf(item);
                              try {
                                return Dismissible(
                                  key: Key(item.filePath),
                                  onDismissed: (direction) async {
                                    bool deleted =
                                        await item.delete(onDeleting: () {
                                      deletedModFiles.add(item.filePath);
                                      modInfos.removeAt(index);
                                      setModState?.call(() {});
                                    });

                                    if (deleted) {
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
                            }).toList(),
                          ),
                        );
                      })
                    ],
                  );
                }
              }),
              actions: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (widget.instanceConfig.loaderEnum == ModLoader.vanilla) {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: I18nText.errorInfoText(),
                                content: I18nText(
                                    "edit.instance.mods.error.vanilla"),
                                actions: [
                                  TextButton(
                                    child: Text(I18n.format("gui.ok")),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ));
                    } else {
                      showDialog(
                          context: context,
                          builder: (context) => ModSourceSelection(
                              widget.instance.uuid, allModInfos ?? []));
                    }
                  },
                  tooltip: I18n.format("gui.mod.add"),
                ),
                IconButton(
                  icon: Icon(Icons.folder),
                  onPressed: () {
                    Uttily.openFileManager(modDir);
                  },
                  tooltip: I18n.format("edit.instance.mods.folder.open"),
                ),
                IconButton(
                  icon: Icon(Icons.restore),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => _CheckModUpdates(
                            modInfos: allModInfos ?? [],
                            instance: widget.instance,
                            setModState: setModState));
                  },
                  tooltip: I18n.format("edit.instance.mods.updater.check"),
                ),
                IconButton(
                  icon: Icon(Icons.file_download),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => _UpdateAllMods(
                              modInfos: allModInfos ?? [],
                              modDir: modDir,
                            ));
                  },
                  tooltip: I18n.format("edit.instance.mods.updater.update_all"),
                )
              ],
            );
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else {
            return _ModInfoLoading(progressPort: progressPort);
          }
        });
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

    return ContextMenuArea(
      items: [
        ListTile(
          title: I18nText("edit.instance.mods.list.delete"),
          subtitle: I18nText("edit.instance.mods.list.delete.description"),
          onTap: () {
            navigator.pop();
            modInfo.delete(onDeleting: () {
              deletedModFiles.add(modInfo.filePath);
              modInfos.removeAt(index);
              setModState?.call(() {});
            });
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
              leading: FutureBuilder<Widget>(
                future: modInfo.getImageWidget(),
                builder:
                    (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                  if (snapshot.hasData) {
                    return SizedBox(
                        child: snapshot.data!, width: 50, height: 50);
                  } else {
                    return SizedBox(width: 50, height: 50, child: RWLLoading());
                  }
                },
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(modName),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) {
                      if (modInfo.needsUpdate) {
                        return Tooltip(
                          message: I18n.format(
                            "edit.instance.mods.updater.update",
                          ),
                          child: IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) => _UpdateMod(
                                        modInfo: modInfo, modDir: modDir));
                              },
                              icon: Icon(Icons.file_download)),
                        );
                      } else {
                        return SizedBox();
                      }
                    },
                  ),
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
                        title: SelectableText(
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
                            curseForgeInfo(modInfo.curseID)
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

class _UpdateAllMods extends StatefulWidget {
  const _UpdateAllMods({
    Key? key,
    required this.modInfos,
    required this.modDir,
  }) : super(key: key);

  final List<ModInfo> modInfos;
  final Directory modDir;

  @override
  State<_UpdateAllMods> createState() => _UpdateAllModsState();
}

class _UpdateAllModsState extends State<_UpdateAllMods> {
  int total = 0;
  int done = 0;
  double _progress = 0.0;
  late bool needUpdate;

  Future<void> updateAllIng() async {
    List<ModInfo> needUpdates =
        widget.modInfos.where((modInfo) => modInfo.needsUpdate).toList();
    total = needUpdates.length;
    for (ModInfo modInfo in needUpdates) {
      await modInfo.updating(widget.modDir);
      done++;
      _progress = done / total;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    needUpdate = widget.modInfos.any((modInfo) => modInfo.needsUpdate);
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      if (needUpdate) {
        updateAllIng();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (needUpdate) {
      if (_progress == 1.0) {
        return AlertDialog(
          title: I18nText.tipsInfoText(),
          content: I18nText("edit.instance.mods.updater.update_all.done"),
          actions: [OkClose()],
        );
      } else {
        return AlertDialog(
          title: I18nText.tipsInfoText(),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              I18nText("edit.instance.mods.updater.updating"),
              I18nText(
                "edit.instance.mods.updater.progress",
                args: {
                  "done": done.toString(),
                  "total": total.toString(),
                },
              ),
              SizedBox(
                height: 12,
              ),
              LinearProgressIndicator(value: _progress)
            ],
          ),
        );
      }
    } else {
      return AlertDialog(
        title: I18nText.tipsInfoText(),
        content: I18nText("edit.instance.mods.updater.update_all.none"),
        actions: [OkClose()],
      );
    }
  }
}

class _UpdateMod extends StatelessWidget {
  const _UpdateMod({Key? key, required this.modInfo, required this.modDir})
      : super(key: key);
  final ModInfo modInfo;
  final Directory modDir;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: modInfo.updating(modDir),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasData) {
          return AlertDialog(
            title: I18nText.tipsInfoText(),
            content: I18nText("edit.instance.mods.updater.done"),
            actions: [OkClose()],
          );
        } else {
          return AlertDialog(
            title: I18nText.tipsInfoText(),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                I18nText("edit.instance.mods.updater.updating"),
                SizedBox(height: 12),
                RWLLoading()
              ],
            ),
          );
        }
      },
    );
  }
}

class _CheckModUpdates extends StatefulWidget {
  const _CheckModUpdates(
      {Key? key,
      required this.modInfos,
      required this.instance,
      required this.setModState})
      : super(key: key);

  final List<ModInfo> modInfos;
  final Instance instance;
  final StateSetter? setModState;

  @override
  State<_CheckModUpdates> createState() => _CheckModUpdatesState();
}

class _CheckModUpdatesState extends State<_CheckModUpdates> {
  late int total;
  int done = 0;
  double _progress = 0.0;

  @override
  void initState() {
    total = widget.modInfos.length;
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) => checking());
  }

  Future<void> checking() async {
    for (ModInfo modInfo in widget.modInfos) {
      /// 更新延遲至少需要5分鐘
      if (modInfo.curseID != null &&
          (modInfo.lastUpdate
                  ?.isBefore(DateTime.now().subtract(Duration(minutes: 5))) ??
              true)) {
        Map? updateData = await CurseForgeHandler.needUpdates(
            modInfo.curseID!,
            widget.instance.config.version,
            widget.instance.config.loaderEnum,
            modInfo.modHash);

        modInfo.lastUpdate = DateTime.now();
        if (updateData != null) {
          modInfo.needsUpdate = true;
          modInfo.lastUpdateData = updateData;
        }
        await modInfo.save();
      }
      done++;
      _progress =
          (widget.modInfos.indexOf(modInfo) + 1) / widget.modInfos.length;

      if (mounted) {
        setState(() {});
      }
    }
    if (mounted) {
      widget.setModState?.call(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1.0) {
      return AlertDialog(
        title: I18nText.tipsInfoText(),
        content: I18nText("edit.instance.mods.updater.check.done"),
        actions: [OkClose()],
      );
    } else {
      return AlertDialog(
        title: I18nText.tipsInfoText(),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            I18nText("edit.instance.mods.updater.checking"),
            I18nText(
              "edit.instance.mods.updater.progress",
              args: {
                "done": done.toString(),
                "total": total.toString(),
              },
            ),
            SizedBox(
              height: 12,
            ),
            LinearProgressIndicator(value: _progress)
          ],
        ),
      );
    }
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

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      widget.progressPort.listen((message) {
        if (message is double && mounted) {
          progress = message;
          setState(() {});
        }
      });
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
        SizedBox(height: 15),
        I18nText("edit.instance.mods.loading", style: TextStyle(fontSize: 30)),
      ],
    );
  }
}

Widget curseForgeInfo(int? curseID) {
  return Builder(builder: (content) {
    if (curseID != null) {
      return IconButton(
        onPressed: () async {
          Map? data = await CurseForgeHandler.getAddonInfo(curseID);
          if (data != null) {
            String pageUrl = data["websiteUrl"];
            Uttily.openUri(pageUrl);
          }
        },
        icon: Icon(Icons.open_in_new),
        tooltip: I18n.format('edit.instance.mods.open_in_curseforge'),
      );
    } else {
      return SizedBox.shrink();
    }
  });
}
