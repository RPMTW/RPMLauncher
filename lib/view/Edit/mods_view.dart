import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/database/data_box.dart';
import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/mod/CurseForge/handler.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/Game/Instance.dart';
import 'package:rpmlauncher/model/Game/mod_info.dart';
import 'package:rpmlauncher/model/IO/isolate_option.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/Logger.dart';
import 'package:rpmlauncher/database/database.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/view/OptionsView.dart';
import 'package:rpmlauncher/widget/ModSourceSelection.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';
import 'package:rpmlauncher/widget/rpmtw_design/RPMTextField.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart' hide ModLoader;
import 'package:toml/toml.dart';

import '../../widget/FileSwitchBox.dart';
import '../../widget/RWLLoading.dart';

class ModsView extends StatefulWidget {
  final Instance instance;

  InstanceConfig get instanceConfig => instance.config;

  const ModsView(this.instance);

  @override
  State<ModsView> createState() => _ModsViewState();
}

class _ModsViewState extends State<ModsView> {
  final TextEditingController modSearchController = TextEditingController();
  final DataBox<String, ModInfo> modInfoBox = Database.instance.modInfoBox;

  StateSetter? setModState;
  late StreamSubscription<FileSystemEvent> modDirEvent;
  late List<FileSystemEntity> files;

  Directory get modDir =>
      InstanceRepository.getModRootDir(widget.instance.uuid);

  late Map<File, ModInfo> modInfos;
  late Map<File, ModInfo> allModInfos;
  List<String> deletedModFiles = [];

  @override
  void initState() {
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

  static ModInfo _getModInfo(
      File modFile, int murmur2Hash, String md5Hash, IsolateOption option) {
    ModLoader modType = ModLoader.unknown;
    try {
      final unzipped = ZipDecoder()
          .decodeBytes(File(modFile.absolute.path).readAsBytesSync());
      List<ConflictMod> conflicts = [];
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
                GameRepository.getModIconFile(md5Hash)
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(i.content as List<int>);
              }
            }
          }
        } catch (err) {
          logger.error(ErrorType.parseModInfo, "Mod Icon Parsing Error $err");
        }

        void _handle(Map map) {
          try {
            Map<String, dynamic> conflictsMap = map.cast<String, dynamic>();
            conflictsMap.forEach((key, value) {
              conflicts.add(ConflictMod(namespace: key, versionID: value));
            });
          } catch (e) {
            logger.error(
                ErrorType.parseModInfo, 'field to handle conflict mods');
          }
        }

        if (modInfoMap.containsKey("conflicts")) {
          _handle(modInfoMap["conflicts"]);
        }
        if (modInfoMap.containsKey("breaks")) {
          _handle(modInfoMap["breaks"]);
        }

        return ModInfo(
            loader: modType,
            name: modInfoMap["name"],
            description: modInfoMap["description"],
            version: modInfoMap["version"],
            curseID: null,
            md5Hash: md5Hash,
            murmur2Hash: murmur2Hash,
            conflicts: conflicts,
            namespace: modInfoMap["id"]);
      } else if (forge113 != null) {
        modType = ModLoader.forge;
        TomlDocument modToml;

        modToml = TomlDocument.parse(const Utf8Decoder(allowMalformed: true)
            .convert(forge113.content as List<int>));

        modInfoMap = modToml.toMap();

        final Map info = modInfoMap["mods"][0];

        if (modInfoMap["logoFile"].toString().isNotEmpty) {
          for (var i in unzipped) {
            if (i.name == modInfoMap["logoFile"]) {
              GameRepository.getModIconFile(md5Hash)
                ..createSync(recursive: true)
                ..writeAsBytesSync(i.content as List<int>);
            }
          }
        }

        return ModInfo(
            loader: modType,
            name: info["displayName"],
            description: info["description"],
            version: info["version"],
            curseID: null,
            md5Hash: md5Hash,
            murmur2Hash: murmur2Hash,
            conflicts: [],
            namespace: info["modId"]);
      } else if (forge112 != null) {
        modType = ModLoader.forge;
        modInfoMap = json.decode(const Utf8Decoder(allowMalformed: true)
            .convert(forge112.content as List<int>))[0];

        if (modInfoMap["logoFile"].toString().isNotEmpty) {
          for (ArchiveFile f in unzipped) {
            if (f.name == modInfoMap["logoFile"]) {
              GameRepository.getModIconFile(md5Hash)
                ..createSync(recursive: true)
                ..writeAsBytesSync(f.content as List<int>);
            }
          }
        }

        return ModInfo(
            loader: modType,
            name: modInfoMap["name"],
            description: modInfoMap["description"],
            version: modInfoMap["version"],
            curseID: null,
            md5Hash: md5Hash,
            murmur2Hash: murmur2Hash,
            conflicts: [],
            namespace: modInfoMap["modid"]);
      } else {
        throw Exception("Unknown ModLoader");
      }
    } catch (e) {
      return ModInfo(
          loader: modType,
          name: modFile.absolute.path
              .split(Platform.pathSeparator)
              .last
              .replaceFirst(".jar", "")
              .replaceFirst(".disable", ""),
          description: 'unknown',
          version: 'unknown',
          curseID: null,
          conflicts: [],
          md5Hash: md5Hash,
          murmur2Hash: murmur2Hash,
          namespace: "unknown");
    }
  }

  /// Returns a map of mod file to mod hash
  static Future<Map<File, String>> getModInfos(
      IsolateOption<List> option) async {
    option.init();
    final DateTime start = DateTime.now();
    final Map<File, String> infos = {};
    final List<FileSystemEntity> files = option.argument[0];
    final Iterable<String> infoKeys = option.argument[1];

    try {
      for (FileSystemEntity modFile in files) {
        if (modFile is File) {
          if (!modFile.existsSync()) continue;

          final int murmur2Hash = Util.getMurmur2Hash(modFile);
          final String md5Hash =
              md5.convert(await modFile.readAsBytes()).toString();

          try {
            if (!infoKeys.contains(md5Hash)) {
              final ModInfo info =
                  _getModInfo(modFile, murmur2Hash, md5Hash, option);
              final List<CurseForgeModFile> matchesFiles = await RPMTWApiClient
                  .instance.curseforgeResource
                  .getFilesByFingerprint([murmur2Hash]);
              final int? curseID;
              if (matchesFiles.isNotEmpty) {
                curseID = matchesFiles.first.id;
              } else {
                curseID = null;
              }

              info.curseID = curseID;
              option.sendData(info, index: 1);
            }
            infos[modFile] = md5Hash;
          } on FormatException catch (e, stackTrace) {
            if (e is! ArchiveException) {
              logger.error(ErrorType.io, e, stackTrace: stackTrace);
            }
          }
        }

        /// send progress
        option.sendData((files.indexOf(modFile) + 1) / files.length);
      }
    } catch (e, stackTrace) {
      logger.error(ErrorType.io, e, stackTrace: stackTrace);
    }

    DateTime end = DateTime.now();
    logger.info("ModInfos loaded in ${end.difference(start).inMilliseconds}ms");
    return infos;
  }

  void filterSearchResults(String query) {
    modInfos = Map<File, ModInfo>.fromEntries(
        allModInfos.entries.where((MapEntry<File, ModInfo> entry) {
      String name = entry.value.name;
      final nameLower = name.toLowerCase();
      final searchLower = query.toLowerCase();
      return nameLower.contains(searchLower);
    }));

    setModState?.call(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ReceivePort progressPort = ReceivePort();

    Future<Map<File, ModInfo>> _get() async {
      final ReceivePort hivePort = ReceivePort();

      final List<ModInfo> needPuts = [];
      hivePort.listen((value) {
        if (value is ModInfo) {
          needPuts.add(value);
        }
      });

      final Map<File, String> hashes = await compute(
          getModInfos,
          IsolateOption.create([files, modInfoBox.keys.cast<String>().toList()],
              ports: [progressPort, hivePort]));

      for (ModInfo info in needPuts) {
        await modInfoBox.put(info.md5Hash, info);
      }

      final List<MapEntry<File, ModInfo>> infos = hashes.entries
          .map((entry) => MapEntry(entry.key, (modInfoBox.get(entry.value))!))
          .toList();

      return Map<File, ModInfo>.fromEntries(infos
        ..sort((a, b) =>
            a.value.name.toLowerCase().compareTo(b.value.name.toLowerCase())));
    }

    return FutureBuilder<Map<File, ModInfo>>(
        future: _get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            allModInfos = snapshot.data!;
            modInfos = allModInfos;

            return OptionPage(
              mainWidget: Builder(builder: (context) {
                if (files.isEmpty) {
                  return Center(
                      child: Text(
                    I18n.format("edit.instance.mods.list.found"),
                    style: const TextStyle(fontSize: 30),
                  ));
                } else {
                  return ListView(
                    shrinkWrap: true,
                    controller: ScrollController(),
                    children: [
                      const SizedBox(
                        height: 12,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
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
                          const SizedBox(
                            width: 12,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      StatefulBuilder(builder: (context, setModState_) {
                        DateTime start = DateTime.now();
                        setModState = setModState_;
                        return SingleChildScrollView(
                          controller: ScrollController(),
                          child: ListBody(
                            children: modInfos.entries
                                .map((MapEntry<File, ModInfo> entry) {
                              ModInfo info = entry.value;
                              try {
                                return Dismissible(
                                  key: Key(info.md5Hash),
                                  onDismissed: (direction) async {
                                    bool deleted = await info
                                        .deleteMod(entry.key, onDeleting: () {
                                      deletedModFiles.add(entry.key.path);
                                      modInfos.remove(entry.key);
                                      setModState?.call(() {});
                                    });

                                    if (deleted && mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: I18nText(
                                        'edit.instance.mods.deleted',
                                        args: {"mod_name": info.name},
                                      )));
                                    }
                                  },
                                  background: Container(color: Colors.red),
                                  child: modListTile(info, entry.key, context),
                                );
                              } catch (error, stackTrace) {
                                logger.error(ErrorType.unknown, error,
                                    stackTrace: stackTrace);
                                return Container();
                              } finally {
                                if (entry.key == modInfos.keys.last) {
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
                  icon: const Icon(Icons.add),
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
                              widget.instance.uuid, allModInfos));
                    }
                  },
                  tooltip: I18n.format("gui.mod.add"),
                ),
                IconButton(
                  icon: const Icon(Icons.folder),
                  onPressed: () {
                    Util.openFileManager(modDir);
                  },
                  tooltip: I18n.format("edit.instance.mods.folder.open"),
                ),
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => _CheckModUpdates(
                            modInfos: allModInfos,
                            instance: widget.instance,
                            setModState: setModState));
                  },
                  tooltip: I18n.format("edit.instance.mods.updater.check"),
                ),
                IconButton(
                  icon: const Icon(Icons.file_download),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => _UpdateAllMods(
                              modInfos: allModInfos,
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

  Widget modListTile(ModInfo modInfo, File file, BuildContext context) {
    if (!file.existsSync()) {
      if (extension(file.path) == '.jar' &&
              File("${file.path}.disable").existsSync() ||
          (extension(file.path) == '.disable' &&
              File(file.path.split(".disable")[0]).existsSync())) {
      } else {
        return const SizedBox();
      }
    }

    String modName = modInfo.name;

    return ContextMenuArea(
      builder: (context) => [
        ListTile(
          title: I18nText("edit.instance.mods.list.delete"),
          subtitle: I18nText("edit.instance.mods.list.delete.description"),
          onTap: () {
            Navigator.pop(context);
            modInfo.deleteMod(file, onDeleting: () {
              deletedModFiles.add(file.path);
              modInfos.remove(file);
              setModState?.call(() {});
            });
          },
        ),
        Builder(builder: (context) {
          bool modSwitch = !file.path.endsWith(".disable");

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
                String newPath;
                if (modSwitch) {
                  modSwitch = false;
                  newPath = "${file.absolute.path}.disable";
                } else {
                  modSwitch = true;
                  newPath = file.absolute.path.split(".disable")[0];
                }
                await file.rename(newPath);

                File newFile = File(newPath);
                ModInfo info = allModInfos[file]!;
                allModInfos.remove(file);
                modInfos.remove(file);
                allModInfos[newFile] = info;
                modInfos[newFile] = info;

                setModState?.call(() {});
              } on FileSystemException {}
              if (mounted) {
                Navigator.of(context).pop();
              }
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
                        width: 50, height: 50, child: snapshot.data!);
                  } else {
                    return const SizedBox(
                        width: 50, height: 50, child: RWLLoading());
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
                                        modInfo: modInfo,
                                        modDir: modDir,
                                        file: file));
                              },
                              icon: const Icon(Icons.file_download)),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                  Builder(builder: (context) {
                    Map<File, ModInfo> conflictMods = Map.fromEntries(
                        allModInfos.entries.where((entry) => entry
                            .value.conflicts
                            .any((mod) => mod.isConflict(modInfo))));

                    if (conflictMods.isNotEmpty) {
                      List<String> conflictModNames = [];
                      conflictMods.forEach((file, info) {
                        conflictModNames.add(info.name);
                      });

                      return Tooltip(
                        message: I18n.format('edit.instance.mods.list.conflict',
                            args: {
                              "mods": conflictModNames
                                  .join(I18n.format('gui.separate'))
                            }),
                        child: const Icon(Icons.warning),
                      );
                    } else {
                      return const SizedBox();
                    }
                  }),
                  Builder(
                    builder: (context) {
                      if (modInfo.loader == widget.instanceConfig.loaderEnum ||
                          modInfo.loader == ModLoader.unknown) {
                        return const SizedBox();
                      } else {
                        return Tooltip(
                            message: I18n.format(
                                "edit.instance.mods.list.conflict.loader",
                                args: {
                                  "modloader": modInfo.loader.name,
                                  "instance_modloader":
                                      widget.instanceConfig.loader
                                }),
                            child: const Icon(Icons.warning));
                      }
                    },
                  ),
                  FileSwitchBox(file: file),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      modInfo.deleteMod(file, onDeleting: () {
                        deletedModFiles.add(file.path);
                        modInfos.remove(file);
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
          const SizedBox(
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

  final Map<File, ModInfo> modInfos;
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
    Map<File, ModInfo> needUpdates = Map.fromEntries(
        widget.modInfos.entries.where((entry) => entry.value.needsUpdate));
    total = needUpdates.length;
    for (MapEntry<File, ModInfo> entry in needUpdates.entries) {
      await entry.value.updating(widget.modDir, entry.key);
      done++;
      _progress = done / total;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    needUpdate =
        widget.modInfos.entries.any((entry) => entry.value.needsUpdate);
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
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
          actions: const [OkClose()],
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
              const SizedBox(
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
        actions: const [OkClose()],
      );
    }
  }
}

class _UpdateMod extends StatelessWidget {
  const _UpdateMod(
      {Key? key,
      required this.modInfo,
      required this.file,
      required this.modDir})
      : super(key: key);
  final ModInfo modInfo;
  final File file;
  final Directory modDir;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: modInfo.updating(modDir, file),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasData) {
          return AlertDialog(
            title: I18nText.tipsInfoText(),
            content: I18nText("edit.instance.mods.updater.done"),
            actions: const [OkClose()],
          );
        } else {
          return AlertDialog(
            title: I18nText.tipsInfoText(),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                I18nText("edit.instance.mods.updater.updating"),
                const SizedBox(height: 12),
                const RWLLoading()
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

  final Map<File, ModInfo> modInfos;
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

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => checking());
  }

  Future<void> checking() async {
    for (MapEntry<File, ModInfo> entry in widget.modInfos.entries) {
      // 更新延遲至少需要5分鐘
      ModInfo info = entry.value;
      File file = entry.key;

      if (info.curseID != null &&
          (info.lastUpdate?.isBefore(
                  DateTime.now().subtract(const Duration(minutes: 5))) ??
              true)) {
        Map? updateData = await CurseForgeHandler.needUpdates(
            info.curseID!,
            widget.instance.config.version,
            widget.instance.config.loaderEnum,
            info.murmur2Hash);

        info.lastUpdate = DateTime.now();
        if (updateData != null) {
          info.needsUpdate = true;
          info.lastUpdateData = updateData;
        }
        try {
          await info.save();
        } catch (e) {}
      }
      done++;
      _progress = (widget.modInfos.keys.toList().indexOf(file) + 1) /
          widget.modInfos.length;

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
      bool press = false;
      Map<File, ModInfo> needUpdates = Map.fromEntries(
          widget.modInfos.entries.where((entry) => entry.value.needsUpdate));

      return AlertDialog(
        title: I18nText.tipsInfoText(),
        content: StatefulBuilder(builder: (context, setState) {
          return SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                I18nText("edit.instance.mods.updater.check.done"),
                Builder(
                  builder: (context) {
                    if (press) {
                      return IconButton(
                        onPressed: () {
                          press = false;
                          setState(() {});
                        },
                        icon: const Icon(Icons.unfold_less),
                      );
                    } else {
                      return IconButton(
                        icon: const Icon(Icons.unfold_more),
                        onPressed: () {
                          press = true;
                          setState(() {});
                        },
                      );
                    }
                  },
                ),
                Builder(
                  builder: (context) {
                    if (press) {
                      return I18nText(
                          "edit.instance.mods.updater.check.can_update");
                    } else {
                      return Container();
                    }
                  },
                ),
                Builder(
                  builder: (context) {
                    if (press) {
                      return ListView.builder(
                        itemBuilder: (context, index) {
                          return Text(
                              needUpdates.entries.elementAt(index).value.name);
                        },
                        shrinkWrap: true,
                        itemCount: needUpdates.length,
                      );
                    } else {
                      return Container();
                    }
                  },
                )
              ],
            ),
          );
        }),
        actions: const [OkClose()],
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
            const SizedBox(
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

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
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
        const SizedBox(height: 30),
        Row(
          children: [
            const SizedBox(
              width: 50,
            ),
            Expanded(child: LinearProgressIndicator(value: progress)),
            const SizedBox(
              width: 50,
            ),
          ],
        ),
        const SizedBox(height: 15),
        I18nText("edit.instance.mods.loading",
            style: const TextStyle(fontSize: 30)),
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
            Util.openUri(pageUrl);
          }
        },
        icon: const Icon(Icons.open_in_new),
        tooltip: I18n.format('edit.instance.mods.open_in_curseforge'),
      );
    } else {
      return const SizedBox.shrink();
    }
  });
}
