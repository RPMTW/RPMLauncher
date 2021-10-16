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
  final String modrinthID;
  final InstanceConfig instanceConfig;
  final List modFileList;
  final Directory modDir;
  final String modName;

  ModrinthModVersion(
      this.modrinthID, this.instanceConfig, this.modDir, this.modName)
      : modFileList = modDir.listSync().whereType<File>().toList();

  @override
  _ModrinthModVersionState createState() => _ModrinthModVersionState();
}

class _ModrinthModVersionState extends State<ModrinthModVersion> {
  List<FileSystemEntity> installedFiles = [];

  @override
  void initState() {
    super.initState();
  }

  Future<Widget> getInstalledWidget(versionInfo) async {
    late FileSystemEntity fse;
    try {
      fse = widget.modFileList.firstWhere((_fse) => CheckData.CheckSha1Sync(
          _fse, versionInfo["files"][0]["hashes"]["sha1"]));
      installedFiles.add(fse);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(I18n.format("edit.instance.mods.download.select.version")),
      content: SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: FutureBuilder(
              future: ModrinthHandler.getModFilesInfo(widget.modrinthID,
                  widget.instanceConfig.version, widget.instanceConfig.loader),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder:
                          (BuildContext fileBuildContext, int versionIndex) {
                        Map versionInfo = snapshot.data[versionIndex];

                        return ListTile(
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: FutureBuilder(
                                future: getInstalledWidget(versionInfo),
                                builder: (context, AsyncSnapshot snapshot) {
                                  if (snapshot.hasData) {
                                    return snapshot.data;
                                  } else {
                                    return CircularProgressIndicator();
                                  }
                                }),
                          ),
                          title: Text(versionInfo["name"]),
                          subtitle: ModrinthHandler.parseReleaseType(
                              versionInfo["version_type"]),
                          onTap: () {
                            File modFile = File(join(
                                widget.modDir.absolute.path,
                                versionInfo["files"][0]["filename"]));
                            final url = versionInfo["files"][0]["url"];
                            installedFiles.forEach((file) {
                              file.deleteSync(recursive: true);
                            });
                            showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) =>
                                  Task(url, modFile, widget.modName),
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
          tooltip: I18n.format("gui.close"),
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
  final File modFile;
  final String modName;

  const Task(this.url, this.modFile, this.modName);

  @override
  _TaskState createState() => _TaskState();
}

class _TaskState extends State<Task> {
  @override
  void initState() {
    super.initState();
    thread(widget.url, widget.modFile);
  }

  static double _progress = 0.0;
  static int downloadedLength = 0;
  static int contentLength = 0;

  thread(url, modFile) async {
    var port = ReceivePort();
    var isolate =
        await Isolate.spawn(Downloading, [url, modFile, port.sendPort]);
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
        title: Text("${I18n.format("gui.download.ing")} ${widget.modName}"),
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
