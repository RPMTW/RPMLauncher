import 'dart:io';
import 'dart:isolate';

import 'package:rpmlauncher/launcher/CheckData.dart';
import 'package:rpmlauncher/mod/modrinth_handler.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/model/IO/isolate_option.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';

import 'RWLLoading.dart';

class ModrinthModVersion extends StatefulWidget {
  final String modrinthID;
  final InstanceConfig instanceConfig;
  final Directory modDir;
  final String modName;

  const ModrinthModVersion(
      this.modrinthID, this.instanceConfig, this.modDir, this.modName);

  @override
  State<ModrinthModVersion> createState() => _ModrinthModVersionState();
}

class _ModrinthModVersionState extends State<ModrinthModVersion> {
  List<FileSystemEntity> installedFiles = [];

  late List<FileSystemEntity> modFileList;

  @override
  void initState() {
    modFileList = widget.modDir.listSync().whereType<File>().toList();
    super.initState();
  }

  Future<Widget> getInstalledWidget(versionInfo) async {
    late FileSystemEntity fse;
    try {
      fse = modFileList.firstWhere((fse) => CheckData.checkSha1Sync(
          fse, versionInfo['files'][0]['hashes']['sha1']));
      installedFiles.add(fse);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check),
          Text(I18n.format('edit.instance.mods.installed'),
              textAlign: TextAlign.center)
        ],
      );
    } catch (e) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.close),
          Text(I18n.format('edit.instance.mods.uninstalled'),
              textAlign: TextAlign.center)
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(I18n.format('edit.instance.mods.download.select.version')),
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
                                    return const CircularProgressIndicator();
                                  }
                                }),
                          ),
                          title: Text(versionInfo['name']),
                          subtitle: ModrinthHandler.parseReleaseType(
                              versionInfo['version_type']),
                          onTap: () {
                            File modFile = File(join(
                                widget.modDir.absolute.path,
                                versionInfo['files'][0]['filename']));
                            final url = versionInfo['files'][0]['url'];
                            installedFiles.forEach((file) {
                              try {
                                file.deleteSync(recursive: true);
                              } on FileSystemException {}
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
                    children: const [RWLLoading()],
                  );
                }
              })),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.close_sharp),
          tooltip: I18n.format('gui.close'),
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
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  @override
  void initState() {
    super.initState();
    thread(widget.url, widget.modFile);
  }

  static double _progress = 0.0;

  thread(url, modFile) async {
    ReceivePort port = ReceivePort();
    ReceivePort exit = ReceivePort();

    await Isolate.spawn(
        downloading, IsolateOption.create([url, modFile], ports: [port]),
        onExit: exit.sendPort);

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

  static downloading(IsolateOption<List> option) async {
    option.init();

    String url = option.argument[0];
    File modFile = option.argument[1];
    await RPMHttpClient().download(url, modFile.path,
        onReceiveProgress: (rec, total) {
      option.sendData(rec / total);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1.0) {
      return AlertDialog(
        title: Text(I18n.format('gui.download.done')),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(I18n.format('gui.close')))
        ],
      );
    } else {
      return AlertDialog(
        title: Text('${I18n.format('gui.download.ing')} ${widget.modName}'),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${(_progress * 100).toStringAsFixed(3)}%'),
            LinearProgressIndicator(value: _progress)
          ],
        ),
      );
    }
  }
}
