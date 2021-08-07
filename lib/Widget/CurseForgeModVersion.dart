import 'dart:io';
import 'dart:isolate';

import 'package:RPMLauncher/Mod/CurseForgeHandler.dart';
import 'package:RPMLauncher/Utility/Config.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';

class CurseForgeModVersion extends StatefulWidget {
  late List Files;
  late int CurseID;
  late Directory ModDir;
  late Map InstanceConfig;

  CurseForgeModVersion(Files_, CurseID_, ModDir_, InstanceConfig_) {
    Files = Files_;
    CurseID = CurseID_;
    ModDir = ModDir_;
    InstanceConfig = InstanceConfig_;
  }

  @override
  CurseForgeModVersion_ createState() =>
      CurseForgeModVersion_(Files, CurseID, ModDir, InstanceConfig);
}

class CurseForgeModVersion_ extends State<CurseForgeModVersion> {
  late List Files;
  late int CurseID;
  late Directory ModDir;
  late Map InstanceConfig;
  late List<FileSystemEntity> ModFileList;

  List<FileSystemEntity> InstalledFiles = [];

  CurseForgeModVersion_(Files_, CurseID_, ModDir_, InstanceConfig_) {
    Files = Files_;
    CurseID = CurseID_;
    ModDir = ModDir_;
    InstanceConfig = InstanceConfig_;
    ModFileList = ModDir_.listSync().toList();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(i18n.Format("edit.instance.mods.download.select.version")),
      content: Container(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: ListView.builder(
              itemCount: Files.length,
              itemBuilder: (BuildContext FileBuildContext, int FileIndex) {
                return FutureBuilder(
                    future: CurseForgeHandler.getFileInfo(
                        CurseID,
                        InstanceConfig["version"],
                        InstanceConfig["loader"],
                        Files[FileIndex]["modLoader"],
                        Files[FileIndex]["projectFileId"]),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.data == null) {
                        return Container();
                      } else if (snapshot.hasData) {
                        Map FileInfo = snapshot.data;

                        bool IsInstalled = ModFileList.any((file) {
                          if (File(file.absolute.path).lengthSync() ==
                              FileInfo["fileLength"]) {
                            InstalledFiles.add(file);
                            return true;
                          } else {
                            return false;
                          }
                        });
                        late Widget InstalledWidget;

                        if (IsInstalled) {
                          InstalledWidget = Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check),
                              Text(i18n.Format("edit.instance.mods.installed"),
                                  textAlign: TextAlign.center)
                            ],
                          );
                        } else {
                          InstalledWidget = Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close),
                              Text(
                                  i18n.Format("edit.instance.mods.uninstalled"),
                                  textAlign: TextAlign.center)
                            ],
                          );
                        }

                        return ListTile(
                          leading: InstalledWidget,
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
                                  ModDir,
                                  InstanceConfig["version"],
                                  InstanceConfig["loader"],
                                  Files[FileIndex]["modLoader"]),
                            );
                          },
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [CircularProgressIndicator()],
                        );
                      }
                    });
              })),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.close_sharp),
          tooltip: i18n.Format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
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
  Task_ createState() => Task_(FileInfo, ModDir, VersionID, Loader, FileLoader);
}

class Task_ extends State<Task> {
  late var FileInfo;
  late Directory ModDir;
  late var VersionID;
  late var Loader;
  late var FileLoader;

  Task_(FileInfo_, ModDir_, VersionID_, Loader_, FileLoader_) {
    FileInfo = FileInfo_;
    ModDir = ModDir_;
    VersionID = VersionID_;
    Loader = Loader_;
    FileLoader = FileLoader_;
  }

  @override
  void initState() {
    super.initState();

    File ModFile = File(join(ModDir.absolute.path, FileInfo["fileName"]));

    final url = FileInfo["downloadUrl"];
    Thread(url, ModFile);

    if (Config().GetValue("auto_dependencies")) {
      DownloadDependenciesFileInfo();
    }
  }

  static double _progress = 0;
  static int downloadedLength = 0;
  static int contentLength = 0;

  DownloadDependenciesFileInfo() async {
    if (FileInfo.containsKey("dependencies")) {
      for (var Dependency in FileInfo["dependencies"]) {
        List DependencyFileInfo = await CurseForgeHandler.getModFiles(
            Dependency["addonId"], VersionID, Loader, FileLoader);
        if (DependencyFileInfo.length < 1) return;
        File ModFile =
            File(join(ModDir.absolute.path, DependencyFileInfo[0]["fileName"]));
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
        print(e);
      },
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1) {
      return AlertDialog(
        title: Text(i18n.Format("gui.download.done")),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(i18n.Format("gui.close")))
        ],
      );
    } else {
      return AlertDialog(
        title: Text(
            "${i18n.Format("gui.download.ing")} ${FileInfo["displayName"].replaceAll(".jar", "")}"),
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
