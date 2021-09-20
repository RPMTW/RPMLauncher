import 'dart:io';
import 'dart:isolate';

import 'package:rpmlauncher/Launcher/CheckData.dart';
import 'package:rpmlauncher/Mod/ModrinthHandler.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/main.dart';

import 'RWLLoading.dart';

class ModrinthModVersion extends StatefulWidget {
  late String ModrinthID;
  late Map InstanceConfig;
  late List ModFileList;
  late Directory ModDir;
  late String ModName;

  ModrinthModVersion(
      ModrinthID_, InstanceConfig_, ModFileList_, ModDir_, ModName_) {
    ModrinthID = ModrinthID_;
    InstanceConfig = InstanceConfig_;
    ModFileList = ModFileList_;
    ModDir = ModDir_;
    ModName = ModName_;
  }

  @override
  ModrinthModVersion_ createState() => ModrinthModVersion_(
      ModrinthID, InstanceConfig, ModFileList, ModDir, ModName);
}

class ModrinthModVersion_ extends State<ModrinthModVersion> {
  late String ModrinthID;
  late Map InstanceConfig;
  late List<FileSystemEntity> ModFileList;
  late Directory ModDir;
  late String ModName;

  List<FileSystemEntity> InstalledFiles = [];

  ModrinthModVersion_(
      ModrinthID_, InstanceConfig_, ModFileList_, ModDir_, ModName_) {
    ModrinthID = ModrinthID_;
    InstanceConfig = InstanceConfig_;
    ModFileList = ModDir_.listSync().where((file) => file is File).toList();
    ModDir = ModDir_;
    ModName = ModName_;
  }

  @override
  void initState() {
    super.initState();
  }

  Future<Widget> InstalledWidget(VersionInfo) async {
    late bool IsInstalled = false;
    ModFileList.forEach((file) async {
      if (await CheckData()
          .CheckSha1(file, VersionInfo["files"][0]["hashes"]["sha1"])) {
        InstalledFiles.add(file);
        IsInstalled = true;
        return;
      }
    });
    if (IsInstalled) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check),
          Text(i18n.format("edit.instance.mods.installed"),
              textAlign: TextAlign.center)
        ],
      );
    } else {
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(i18n.format("edit.instance.mods.download.select.version")),
      content: Container(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: FutureBuilder(
              future: ModrinthHandler.getModFilesInfo(ModrinthID,
                  InstanceConfig["version"], InstanceConfig["loader"]),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder:
                          (BuildContext FileBuildContext, int VersionIndex) {
                        Map VersionInfo = snapshot.data[VersionIndex];

                        return ListTile(
                          leading: FutureBuilder(
                              future: InstalledWidget(VersionInfo),
                              builder: (context, AsyncSnapshot snapshot) {
                                if (snapshot.hasData) {
                                  return snapshot.data;
                                } else {
                                  return RWLLoading();
                                }
                              }),
                          title: Text(VersionInfo["name"]),
                          subtitle: ModrinthHandler.ParseReleaseType(
                              VersionInfo["version_type"]),
                          onTap: () {
                            File ModFile = File(join(ModDir.absolute.path,
                                VersionInfo["files"][0]["filename"]));
                            final url = VersionInfo["files"][0]["url"];
                            InstalledFiles.forEach((file) {
                              file.deleteSync(recursive: true);
                            });
                            showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) => Task(url, ModFile, ModName),
                            );
                          },
                        );
                      });
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [RWLLoading()],
                  );
                }
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
}

class Task extends StatefulWidget {
  late var url;
  late var ModFile;
  late var ModName;

  Task(url_, ModFile_, ModName_) {
    url = url_;
    ModFile = ModFile_;
    ModName = ModName_;
  }

  @override
  Task_ createState() => Task_(url, ModFile, ModName);
}

class Task_ extends State<Task> {
  late var url;
  late var ModFile;
  late var ModName;

  Task_(url_, ModFile_, ModName_) {
    url = url_;
    ModFile = ModFile_;
    ModName = ModName_;
  }

  @override
  void initState() {
    super.initState();
    Thread(url, ModFile);
  }

  static double _progress = 0;
  static int downloadedLength = 0;
  static int contentLength = 0;

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
        title: Text("${i18n.format("gui.download.ing")} ${ModName}"),
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
