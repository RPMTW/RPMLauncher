import 'dart:io';
import 'dart:isolate';

import 'package:rpmlauncher/Launcher/CheckData.dart';
import 'package:rpmlauncher/Mod/ModrinthHandler.dart';
import 'package:rpmlauncher/Model/Instance.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/main.dart';

import 'RWLLoading.dart';

class ModrinthModVersion extends StatefulWidget {
  late String ModrinthID;
  late InstanceConfig instanceConfig;
  late List ModFileList;
  late Directory ModDir;
  late String ModName;

  ModrinthModVersion(
      this.ModrinthID, this.instanceConfig, this.ModDir, this.ModName)
      : ModFileList = ModDir.listSync().whereType<File>().toList();

  @override
  ModrinthModVersion_ createState() => ModrinthModVersion_();
}

class ModrinthModVersion_ extends State<ModrinthModVersion> {
  List<FileSystemEntity> installedFiles = [];

  @override
  void initState() {
    super.initState();
  }

  Future<Widget> getInstalledWidget(versionInfo) async {
    late FileSystemEntity fse;
    try {
      fse = widget.ModFileList.firstWhere((_fse) => CheckData.CheckSha1Sync(
          _fse, versionInfo["files"][0]["hashes"]["sha1"]));
      installedFiles.add(fse);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(i18n.format("edit.instance.mods.download.select.version")),
      content: SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: FutureBuilder(
              future: ModrinthHandler.getModFilesInfo(widget.ModrinthID,
                  widget.instanceConfig.version, widget.instanceConfig.loader),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder:
                          (BuildContext fileBuildContext, int VersionIndex) {
                        Map VersionInfo = snapshot.data[VersionIndex];

                        return ListTile(
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: FutureBuilder(
                                future: getInstalledWidget(VersionInfo),
                                builder: (context, AsyncSnapshot snapshot) {
                                  if (snapshot.hasData) {
                                    return snapshot.data;
                                  } else {
                                    return CircularProgressIndicator();
                                  }
                                }),
                          ),
                          title: Text(VersionInfo["name"]),
                          subtitle: ModrinthHandler.ParseReleaseType(
                              VersionInfo["version_type"]),
                          onTap: () {
                            File ModFile = File(join(
                                widget.ModDir.absolute.path,
                                VersionInfo["files"][0]["filename"]));
                            final url = VersionInfo["files"][0]["url"];
                            installedFiles.forEach((file) {
                              file.deleteSync(recursive: true);
                            });
                            showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) =>
                                  Task(url, ModFile, widget.ModName),
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
  final String url;
  final File ModFile;
  final String ModName;

  const Task(this.url, this.ModFile, this.ModName);

  @override
  Task_ createState() => Task_();
}

class Task_ extends State<Task> {
  @override
  void initState() {
    super.initState();
    Thread(widget.url, widget.ModFile);
  }

  static double _progress = 0.0;
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
    if (_progress == 1.0) {
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
        title: Text("${i18n.format("gui.download.ing")} ${widget.ModName}"),
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
