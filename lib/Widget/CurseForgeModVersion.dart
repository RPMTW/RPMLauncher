import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';

import 'RWLLoading.dart';

class CurseForgeModVersion extends StatefulWidget {
  final List files;
  final int curseID;
  final Directory modDir;
  final InstanceConfig instanceConfig;

  const CurseForgeModVersion(
      {required this.files,
      required this.curseID,
      required this.modDir,
      required this.instanceConfig});

  @override
  _CurseForgeModVersionState createState() => _CurseForgeModVersionState();
}

class _CurseForgeModVersionState extends State<CurseForgeModVersion> {
  List<FileSystemEntity> get modFileList =>
      widget.modDir.listSync().whereType<File>().toList();
  List<FileSystemEntity> installedFiles = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(I18n.format("edit.instance.mods.download.select.version")),
      content: SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: ListView.builder(
              itemCount: widget.files.length,
              itemBuilder: (BuildContext fileBuildContext, int fileIndex) {
                return FutureBuilder(
                    future: CurseForgeHandler.getFileInfoByVersion(
                        widget.curseID,
                        widget.instanceConfig.version,
                        widget.instanceConfig.loader,
                        widget.files[fileIndex]["modLoader"] ?? 1,
                        widget.files[fileIndex]["projectFileId"]),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.data == null) {
                        return Container();
                      } else if (snapshot.hasData) {
                        Map fileInfo = snapshot.data;
                        return ListTile(
                          leading: FutureBuilder(
                              future: installedWidget(fileInfo),
                              builder: (context, AsyncSnapshot snapshot) {
                                if (snapshot.hasData) {
                                  return snapshot.data;
                                } else {
                                  return CircularProgressIndicator();
                                }
                              }),
                          title: Text(
                              fileInfo["displayName"].replaceAll(".jar", "")),
                          subtitle: CurseForgeHandler.parseReleaseType(
                              fileInfo["releaseType"]),
                          onTap: () {
                            installedFiles.forEach((file) {
                              file.deleteSync(recursive: true);
                            });
                            showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) => Task(
                                  fileInfo,
                                  widget.modDir,
                                  widget.instanceConfig.version,
                                  widget.instanceConfig.loader,
                                  widget.files[fileIndex]["modLoader"] ?? 1),
                            );
                          },
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [RWLLoading()],
                        );
                      }
                    });
              })),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.close_sharp),
          tooltip: I18n.format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Future<Widget> installedWidget(Map fileInfo) async {
    late FileSystemEntity entity;
    try {
      entity = modFileList.firstWhere((fse) {
        if (fse is File) {
          return Uttily.murmurhash2(fse) == fileInfo["packageFingerprint"];
        } else {
          return false;
        }
      });
      installedFiles.add(entity);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check),
          Text(I18n.format("edit.instance.mods.installed"),
              textAlign: TextAlign.center)
        ],
      );
    } catch (e) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.close),
          Text(I18n.format("edit.instance.mods.uninstalled"),
              textAlign: TextAlign.center)
        ],
      );
    }
  }
}

class Task extends StatefulWidget {
  final Map fileInfo;
  final Directory modDir;
  final String versionID;
  final String loader;
  final int fileLoader;

  const Task(
      this.fileInfo, this.modDir, this.versionID, this.loader, this.fileLoader);

  @override
  _TaskState createState() => _TaskState();
}

class _TaskState extends State<Task> {
  bool finish = false;

  @override
  void initState() {
    super.initState();

    thread();
  }

  double _progress = 0;

  Future<DownloadInfos> getDownloadInfos() async {
    DownloadInfos _infos = DownloadInfos.none();

    if (Config.getValue("auto_dependencies")) {
      if (widget.fileInfo.containsKey("dependencies")) {
        for (Map dependency in widget.fileInfo["dependencies"]) {
          List dependencyFileInfo =
              await CurseForgeHandler.getAddonFilesByVersion(
                  dependency["addonId"],
                  widget.versionID,
                  widget.loader,
                  widget.fileLoader);
          if (dependencyFileInfo.length > 1) {
            _infos.add(DownloadInfo(
              dependencyFileInfo.first["downloadUrl"],
              savePath: join(widget.modDir.absolute.path,
                  dependencyFileInfo.first["fileName"]),
            ));
          }
        }
      }
    }

    _infos.add(DownloadInfo(widget.fileInfo["downloadUrl"],
        savePath:
            join(widget.modDir.absolute.path, widget.fileInfo["fileName"])));

    return _infos;
  }

  thread() async {
    DownloadInfos infos = await getDownloadInfos();

    ReceivePort port = ReceivePort();
    Isolate isolate = await Isolate.spawn(downloading, [infos, port.sendPort]);
    ReceivePort exit = ReceivePort();
    isolate.addOnExitListener(exit.sendPort);
    exit.listen((message) {
      if (message == null) {
        // A null message means the isolate exited
      }
    });
    port.listen((message) {
      if (message == 1.0) {
        finish = true;
      }
      setState(() {
        _progress = message;
      });
    });
  }

  static downloading(List args) async {
    DownloadInfos infos = args[0];
    SendPort port = args[1];

    await infos.downloadAll(onReceiveProgress: (value) {
      port.send(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1.0 && finish) {
      return AlertDialog(
        title: Text(I18n.format("gui.download.done")),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(I18n.format("gui.close")))
        ],
      );
    } else {
      return AlertDialog(
        title: Text(
            "${I18n.format("gui.download.ing")} ${widget.fileInfo["displayName"].replaceAll(".jar", "")}"),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${(_progress * 100).toStringAsFixed(3)}%"),
            LinearProgressIndicator(value: _progress)
          ],
        ),
      );
    }
  }
}
