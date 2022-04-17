import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/mod/ModLoader.dart';
import 'package:rpmlauncher/model/Game/ModInfo.dart';
import 'package:rpmlauncher/model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/model/Game/Instance.dart';
import 'package:rpmlauncher/util/Config.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

import 'RWLLoading.dart';

class CurseForgeModVersion extends StatefulWidget {
  final int curseID;
  final Directory modDir;
  final InstanceConfig instanceConfig;
  final List<ModInfo> modInfos;

  const CurseForgeModVersion(
      {required this.curseID,
      required this.modDir,
      required this.instanceConfig,
      required this.modInfos});

  @override
  State<CurseForgeModVersion> createState() => _CurseForgeModVersionState();
}

class _CurseForgeModVersionState extends State<CurseForgeModVersion> {
  List<File> installedFiles = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map>?>(
        future: CurseForgeHandler.getAddonFiles(widget.curseID),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Map> data = snapshot.data!;
            List<Map> files = [];
            final String gameVersion = widget.instanceConfig.version;
            final String loader =
                widget.instanceConfig.loaderEnum.fixedString.toCapitalized();

            data.forEach((file) {
              //過濾版本
              List gameVersions = file["gameVersion"] as List;
              if ((gameVersions).any((v) => v == gameVersion) &&
                  (gameVersions).any((v) => v == loader)) {
                files.add(file);
              }
            });
            files.sort((a, b) => DateTime.parse(a["fileDate"])
                .compareTo(DateTime.parse(b["fileDate"])));
            files = files.reversed.toList();

            return AlertDialog(
              title: Text(
                  I18n.format("edit.instance.mods.download.select.version")),
              content: SizedBox(
                  height: MediaQuery.of(context).size.height / 3,
                  width: MediaQuery.of(context).size.width / 3,
                  child: ListView.builder(
                      itemCount: files.length,
                      itemBuilder:
                          (BuildContext fileBuildContext, int fileIndex) {
                        Map fileInfo = files[fileIndex];
                        return ListTile(
                          leading: FutureBuilder(
                              future: installedWidget(fileInfo),
                              builder: (context, AsyncSnapshot snapshot) {
                                if (snapshot.hasData) {
                                  return snapshot.data;
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              }),
                          title: Text(
                              fileInfo["displayName"].replaceAll(".jar", ""),
                              style: const TextStyle(fontSize: 17)),
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CurseForgeHandler.parseReleaseType(
                                  fileInfo["releaseType"]),
                              Text(Util.formatDate(
                                  DateTime.parse(fileInfo["fileDate"]))),
                            ],
                          ),
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
                                widget.instanceConfig.loaderEnum,
                              ),
                            );
                          },
                        );
                      })),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.close_sharp),
                  tooltip: I18n.format("gui.close"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          } else {
            return const RWLLoading();
          }
        });
  }

  Future<Widget> installedWidget(Map fileInfo) async {
    late ModInfo info;
    try {
      info = widget.modInfos
          .firstWhere((info) => info.modHash == fileInfo["packageFingerprint"]);
      installedFiles.add(info.file);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check),
          Text(I18n.format("edit.instance.mods.installed"),
              textAlign: TextAlign.center)
        ],
      );
    } catch (e) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.close),
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
  final ModLoader loader;
  final bool autoClose;

  const Task(this.fileInfo, this.modDir, this.versionID, this.loader,
      {this.autoClose = false});

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  bool finish = false;
  final DownloadInfos _downloadInfos = DownloadInfos.empty();

  @override
  void initState() {
    super.initState();
    thread();
  }

  double _progress = 0;
  double _progress2 = 0;

  Future<DownloadInfos> getDownloadInfos() async {
    if (Config.getValue("auto_dependencies")) {
      if (widget.fileInfo.containsKey("dependencies")) {
        for (Map dependency in widget.fileInfo["dependencies"]) {
          List<Map>? dependencyFileInfo =
              await CurseForgeHandler.getAddonFilesByVersion(
                  dependency["addonId"], widget.versionID, widget.loader,
                  ignoreCheck: true);

          if (dependencyFileInfo == null) {
            continue;
          }

          if (dependencyFileInfo.length > 1) {
            _downloadInfos.add(DownloadInfo(
              dependencyFileInfo.first["downloadUrl"],
              savePath: join(widget.modDir.absolute.path,
                  dependencyFileInfo.first["fileName"]),
            ));
          }
        }
      }
    }

    _downloadInfos.add(DownloadInfo(widget.fileInfo["downloadUrl"],
        savePath:
            join(widget.modDir.absolute.path, widget.fileInfo["fileName"])));

    return _downloadInfos;
  }

  thread() async {
    DownloadInfos infos = await getDownloadInfos();

    ReceivePort progressPort = ReceivePort();
    ReceivePort allProgressPort = ReceivePort();

    await Isolate.spawn(
        downloading, [infos, progressPort.sendPort, allProgressPort.sendPort]);
    progressPort.listen((message) {
      setState(() {
        _progress = message;
      });
      if (message == 1.0) {
        finish = true;
      }
    });
    allProgressPort.listen((message) {
      setState(() {
        _progress2 = message;
      });
    });
  }

  static downloading(List args) async {
    DownloadInfos infos = args[0];
    SendPort port = args[1];
    SendPort port2 = args[2];

    await infos.downloadAll(
      onReceiveProgress: (value) {
        port.send(value);
      },
      onAllDownloading: (progress) => port2.send(progress),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1.0 && finish) {
      if (widget.autoClose) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
        return const SizedBox();
      } else {
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
      }
    } else {
      return AlertDialog(
        title: Text(
            "${I18n.format("gui.download.ing")} ${widget.fileInfo["displayName"].replaceAll(".jar", "")}"),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${(_progress2 * 100).toStringAsFixed(3)}%"),
            LinearProgressIndicator(value: _progress2),
            ...(_downloadInfos.infos.length > 1
                ? [
                    const SizedBox(
                      height: 10,
                    ),
                    LinearProgressIndicator(value: _progress)
                  ]
                : [])
          ],
        ),
      );
    }
  }
}
