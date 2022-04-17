import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dart_minecraft/dart_nbt.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/Utility.dart';
import 'package:rpmlauncher/view/OptionsView.dart';
import 'package:rpmlauncher/widget/DeleteFileWidget.dart';
import 'package:rpmlauncher/widget/RWLLoading.dart';

class WorldView extends StatefulWidget {
  final Directory worldRootDir;

  const WorldView({Key? key, required this.worldRootDir}) : super(key: key);

  @override
  State<WorldView> createState() => _WorldViewState();
}

class _WorldViewState extends State<WorldView> {
  late ScrollController _scrollController;

  Future<List<FileSystemEntity>> getWorldList() async {
    List<FileSystemEntity> worldList = [];
    widget.worldRootDir.listSync().toList().forEach((dir) {
      //過濾不是世界的資料夾
      if (dir is Directory &&
          Directory(dir.path)
              .listSync()
              .toList()
              .any((file) => file.path.contains("level.dat"))) {
        worldList.add(dir);
      }
    });
    return worldList;
  }

  late StreamSubscription<FileSystemEvent> worldDirEvent;

  @override
  void initState() {
    _scrollController = ScrollController();

    super.initState();

    worldDirEvent = widget.worldRootDir.watch().listen((event) {
      if (!widget.worldRootDir.existsSync()) worldDirEvent.cancel();
      setState(() {});
    });
  }

  @override
  void dispose() {
    worldDirEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OptionPage(
        mainWidget: FutureBuilder(
          future: getWorldList(),
          builder: (context, AsyncSnapshot<List<FileSystemEntity>> snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return Center(
                    child: Text(
                  I18n.format('edit.instance.world.found'),
                  style: const TextStyle(fontSize: 30),
                ));
              }
              return ListView.builder(
                itemCount: snapshot.data!.length,
                controller: _scrollController,
                itemBuilder: (context, index) {
                  late Widget image;
                  Directory worldDir = snapshot.data![index] as Directory;
                  try {
                    if (FileSystemEntity.typeSync(
                            File(join(worldDir.absolute.path, "icon.png"))
                                .absolute
                                .path) !=
                        FileSystemEntityType.notFound) {
                      image = Image.file(
                          File(join(worldDir.absolute.path, "icon.png")),
                          fit: BoxFit.contain);
                    } else {
                      image = const Icon(Icons.image, size: 50);
                    }
                  } on FileSystemException {}
                  try {
                    final nbtReader = NbtReader.fromFile(
                        join(worldDir.absolute.path, "level.dat"));
                    NbtCompound nbtData = nbtReader
                        .read()
                        .getChildrenByName("Data")[0] as NbtCompound;

                    String worldName =
                        nbtData.getChildrenByName("LevelName")[0].value;

                    String? worldVersion;

                    try {
                      worldVersion = (nbtData.getChildrenByName("Version")[0]
                              as NbtCompound)
                          .getChildrenByName("Name")[0]
                          .value;
                    } catch (e) {}

                    int lastPlayed =
                        nbtData.getChildrenByName("LastPlayed")[0].value;

                    return ListTile(
                        leading: image,
                        title: Text(
                          worldName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ),
                        subtitle: Text(
                            "${I18n.format("game.version")}: $worldVersion",
                            textAlign: TextAlign.center),
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                    title: Text(
                                        I18n.format("edit.instance.world.info"),
                                        textAlign: TextAlign.center),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                            "${I18n.format("edit.instance.world.name")}: $worldName"),
                                        Text(
                                            "${I18n.format("game.version")}: $worldVersion"),
                                        Text(
                                            "${I18n.format("edit.instance.world.time")}: ${DateFormat.yMMMMEEEEd(Platform.localeName).add_jms().format(DateTime.fromMillisecondsSinceEpoch(lastPlayed))}")
                                      ],
                                    ));
                              });
                          setState(() {});
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.folder),
                              tooltip:
                                  I18n.format('edit.instance.world.folder'),
                              onPressed: () {
                                Uttily.openFileManager(worldDir);
                              },
                            ),
                            DeleteFileWidget(
                              tooltip: I18n.format(
                                  'edit.instance.world.delete.title'),
                              message: I18n.format(
                                  "edit.instance.world.delete.message"),
                              onDeleted: () {
                                setState(() {});
                              },
                              fileSystemEntity: worldDir,
                            ),
                          ],
                        ));
                  } on FileSystemException {
                    return Container();
                  }
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            } else {
              return const Center(child: RWLLoading());
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final FilePickerResult? result = await FilePicker.platform
                  .pickFiles(
                      dialogTitle: I18n.format("edit.instance.world.zip"),
                      allowedExtensions: ['zip']);

              if (result == null) {
                return;
              }

              PlatformFile file = result.files.single;

              Future<bool> unWorldZip() async {
                final File worldZipFile = File(file.path!);
                final bytes = worldZipFile.readAsBytesSync();
                final archive = ZipDecoder().decodeBytes(bytes);
                bool isParentFolder = archive.files
                    .any((file) => file.toString().startsWith("level.dat"));
                bool isnotParentFolder = archive.files
                    .any((file) => file.toString().contains("level.dat"));
                if (isParentFolder) {
                  //只有一層資料夾
                  final worldDirName =
                      file.name.split(extension(file.path!)).join("");
                  for (final archiveFile in archive) {
                    final zipFileName = archiveFile.name;
                    if (archiveFile.isFile) {
                      await Future.delayed(const Duration(microseconds: 50));
                      final data = archiveFile.content as List<int>;
                      File(join(widget.worldRootDir.absolute.path, worldDirName,
                          zipFileName))
                        ..createSync(recursive: true)
                        ..writeAsBytesSync(data);
                    } else {
                      await Future.delayed(const Duration(microseconds: 50));
                      Directory(join(widget.worldRootDir.absolute.path,
                              worldDirName, zipFileName))
                          .create(recursive: true);
                    }
                  }
                  return true;
                } else if (isnotParentFolder) {
                  //有兩層資料夾
                  for (final archiveFile in archive) {
                    final zipFileName = archiveFile.name;
                    if (archiveFile.isFile) {
                      await Future.delayed(const Duration(microseconds: 50));
                      final data = archiveFile.content as List<int>;
                      File(join(widget.worldRootDir.absolute.path, zipFileName))
                        ..createSync(recursive: true)
                        ..writeAsBytesSync(data);
                    } else {
                      await Future.delayed(const Duration(microseconds: 50));
                      Directory(join(
                              widget.worldRootDir.absolute.path, zipFileName))
                          .create(recursive: true);
                    }
                  }
                  return true;
                } else {
                  //錯誤格式
                  Navigator.of(context).pop();
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Text(I18n.format("gui.error.info"),
                                textAlign: TextAlign.center),
                            content: Text(
                                I18n.format('edit.instance.world.add.error'),
                                textAlign: TextAlign.center),
                            actions: <Widget>[
                              TextButton(
                                child: Text(I18n.format("gui.ok")),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              )
                            ]);
                      });
                  return false;
                }
              }

              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return FutureBuilder(
                        future: unWorldZip(),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData && snapshot.data) {
                            return AlertDialog(
                                title: Text(I18n.format("gui.tips.info")),
                                content: Text(I18n.format('gui.handler.done'),
                                    textAlign: TextAlign.center),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(I18n.format("gui.ok")),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  )
                                ]);
                          } else {
                            return AlertDialog(
                              title: Text(I18n.format("gui.tips.info")),
                              content: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const RWLLoading(),
                                  const SizedBox(width: 12),
                                  I18nText("edit.instance.world.parseing"),
                                ],
                              ),
                            );
                          }
                        });
                  });
            },
            tooltip: I18n.format("edit.instance.world.add"),
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              Uttily.openFileManager(widget.worldRootDir);
            },
            tooltip: I18n.format("edit.instance.world.folder"),
          )
        ]);
  }
}
