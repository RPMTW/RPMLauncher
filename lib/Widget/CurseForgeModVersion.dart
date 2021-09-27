import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:rpmlauncher/main.dart';

import 'RWLLoading.dart';

class CurseForgeModVersion extends StatefulWidget {
  final List Files;
  final int CurseID;
  final Directory ModDir;
  final InstanceConfig instanceConfig;

  CurseForgeModVersion(
      {required this.Files,
      required this.CurseID,
      required this.ModDir,
      required this.instanceConfig});

  @override
  CurseForgeModVersion_ createState() => CurseForgeModVersion_();
}

class CurseForgeModVersion_ extends State<CurseForgeModVersion> {
  List<FileSystemEntity> get ModFileList =>
      widget.ModDir.listSync().where((file) => file is File).toList();
  List<FileSystemEntity> InstalledFiles = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(i18n.format("edit.instance.mods.download.select.version")),
      content: Container(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: ListView.builder(
              itemCount: widget.Files.length,
              itemBuilder: (BuildContext FileBuildContext, int FileIndex) {
                return FutureBuilder(
                    future: CurseForgeHandler.getFileInfoByVersion(
                        widget.CurseID,
                        widget.instanceConfig.version,
                        widget.instanceConfig.loader,
                        widget.Files[FileIndex]["modLoader"],
                        widget.Files[FileIndex]["projectFileId"]),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.data == null) {
                        return Container();
                      } else if (snapshot.hasData) {
                        Map FileInfo = snapshot.data;
                        return ListTile(
                          leading: FutureBuilder(
                              future: InstalledWidget(FileInfo),
                              builder: (context, AsyncSnapshot snapshot) {
                                if (snapshot.hasData) {
                                  return snapshot.data;
                                } else {
                                  return CircularProgressIndicator();
                                }
                              }),
                          title: Text(
                              FileInfo["displayName"].replaceAll(".jar", "")),
                          subtitle: CurseForgeHandler.ParseReleaseType(
                              FileInfo["releaseType"]),
                          onTap: () {
                            InstalledFiles.forEach((file) {
                              file.deleteSync(recursive: true);
                            });
                            showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) => Task(
                                  FileInfo,
                                  widget.ModDir,
                                  widget.instanceConfig.version,
                                  widget.instanceConfig.loader,
                                  widget.Files[FileIndex]["modLoader"]),
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
          tooltip: i18n.format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Future<Widget> InstalledWidget(Map FileInfo) async {
    late FileSystemEntity FSE;
    try {
      FSE = ModFileList.firstWhere((_FSE) {
        if (_FSE is File) {
          return utility.murmurhash2(_FSE) == FileInfo["packageFingerprint"];
        } else {
          return false;
        }
      });
      InstalledFiles.add(FSE);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check),
          Text(i18n.format("edit.instance.mods.installed"),
              textAlign: TextAlign.center)
        ],
      );
    } catch (e) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.close),
          Text(i18n.format("edit.instance.mods.uninstalled"),
              textAlign: TextAlign.center)
        ],
      );
    }
  }
}

class Task extends StatefulWidget {
  late var FileInfo;
  late Directory ModDir;
  late var VersionID;
  late var Loader;
  late var FileLoader;

  Task(FileInfo_, ModDir_, VersionID_, Loader_, FileLoader_) {
    FileInfo = FileInfo_;
    ModDir = ModDir_;
    VersionID = VersionID_;
    Loader = Loader_;
    FileLoader = FileLoader_;
  }

  @override
  Task_ createState() => Task_();
}

class Task_ extends State<Task> {
  @override
  void initState() {
    super.initState();

    File ModFile =
        File(join(widget.ModDir.absolute.path, widget.FileInfo["fileName"]));

    final url = widget.FileInfo["downloadUrl"];
    Thread(url, ModFile);

    if (Config.getValue("auto_dependencies")) {
      DownloadDependenciesFileInfo();
    }
  }

  static double _progress = 0;
  static int downloadedLength = 0;
  static int contentLength = 0;

  DownloadDependenciesFileInfo() async {
    if (widget.FileInfo.containsKey("dependencies")) {
      for (var Dependency in widget.FileInfo["dependencies"]) {
        List DependencyFileInfo =
            await CurseForgeHandler.getAddonFilesByVersion(
                Dependency["addonId"],
                widget.VersionID,
                widget.Loader,
                widget.FileLoader);
        if (DependencyFileInfo.length < 1) return;
        File ModFile = File(join(
            widget.ModDir.absolute.path, DependencyFileInfo[0]["fileName"]));
        final url = DependencyFileInfo[0]["downloadUrl"];
        Thread(url, ModFile);
      }
    }
  }

  Thread(url, ModFile) async {
    var port = ReceivePort();
    var isolate =
        await Isolate.spawn(Downloading, [url, ModFile, port.sendPort]);
    var exit = ReceivePort();
    isolate.addOnExitListener(exit.sendPort);
    exit.listen((message) {
      if (message == null) {
        // A null message means the isolate exited
      }
    });
    port.listen((message) {
      setState(() {
        _progress = message;
      });
    });
  }

  static Downloading(List args) async {
    String url = args[0];
    File ModFile = args[1];
    SendPort port = args[2];
    final request = Request('GET', Uri.parse(url));
    final StreamedResponse response = await Client().send(request);
    contentLength += response.contentLength!;
    List<int> bytes = [];
    response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        downloadedLength += newBytes.length;
        port.send(downloadedLength / contentLength);
      },
      onDone: () async {
        await ModFile.writeAsBytes(bytes);
      },
      onError: (e) {
        logger.send(e);
      },
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1) {
      return AlertDialog(
        title: Text(i18n.format("gui.download.done")),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(i18n.format("gui.close")))
        ],
      );
    } else {
      return AlertDialog(
        title: Text(
            "${i18n.format("gui.download.ing")} ${widget.FileInfo["displayName"].replaceAll(".jar", "")}"),
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
