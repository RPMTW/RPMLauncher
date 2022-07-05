import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/mod/curseforge/curseforge_handler.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/Game/mod_info.dart';
import 'package:rpmlauncher/model/IO/download_info.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/model/IO/isolate_option.dart';
import 'package:rpmlauncher/util/Config.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart' hide ModLoader;
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

import 'rwl_loading.dart';

class CurseForgeModVersion extends StatefulWidget {
  final int curseID;
  final Directory modDir;
  final InstanceConfig instanceConfig;
  final Map<File, ModInfo> modInfos;

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
    return FutureBuilder<List<CurseForgeModFile>>(
        future: RPMTWApiClient.instance.curseforgeResource
            .getModFiles(widget.curseID),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<CurseForgeModFile> files = [];
            final String gameVersion = widget.instanceConfig.version;
            final String loader =
                widget.instanceConfig.loaderEnum.name.toCapitalized();

            snapshot.data!.forEach((file) {
              //過濾版本
              List<String> gameVersions = file.gameVersions;
              if (gameVersions.any((v) => v == gameVersion) &&
                  gameVersions.any((v) => v == loader)) {
                files.add(file);
              }
            });
            files.sort((a, b) => DateTime.parse(b.fileDate)
                .compareTo(DateTime.parse(a.fileDate)));

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
                        CurseForgeModFile file = files[fileIndex];

                        return ListTile(
                          leading: FutureBuilder(
                              future: installedWidget(file),
                              builder: (context, AsyncSnapshot snapshot) {
                                if (snapshot.hasData) {
                                  return snapshot.data;
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              }),
                          title: Text(file.displayName.replaceAll(".jar", ""),
                              style: const TextStyle(fontSize: 17)),
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CurseForgeHandler.parseReleaseType(
                                  file.releaseType),
                              Text(Util.formatDate(
                                  DateTime.parse(file.fileDate))),
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
                                file,
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

  Future<Widget> installedWidget(CurseForgeModFile file) async {
    late MapEntry<File, ModInfo> entry;
    try {
      entry = widget.modInfos.entries.firstWhere(
          (entry) => entry.value.murmur2Hash == file.fileFingerprint);

      installedFiles.add(entry.key);
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
  final CurseForgeModFile file;
  final Directory modDir;
  final String versionID;
  final ModLoader loader;
  final bool autoClose;

  const Task(this.file, this.modDir, this.versionID, this.loader,
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
      /// Find required dependencies.
      List<Dependency> dependencies = widget.file.dependencies
          .where((e) => e.relationType == 3)
          .toSet()
          .toList();

      if (dependencies.isNotEmpty) {
        for (Dependency dependency in dependencies) {
          List<CurseForgeModFile>? dependencyFiles =
              await RPMTWApiClient.instance.curseforgeResource.getModFiles(
            dependency.modId,
            gameVersion: widget.versionID,
            modLoaderType: widget.loader.toCurseForgeType(),
          );

          if (dependencyFiles.isNotEmpty) {
            _downloadInfos.add(DownloadInfo(
              dependencyFiles.first.downloadUrl,
              savePath: join(
                  widget.modDir.absolute.path, dependencyFiles.first.fileName),
            ));
          }
        }
      }
    }

    _downloadInfos.add(DownloadInfo(widget.file.downloadUrl,
        savePath: join(widget.modDir.absolute.path, widget.file.fileName)));

    return _downloadInfos;
  }

  thread() async {
    DownloadInfos infos = await getDownloadInfos();

    ReceivePort progressPort = ReceivePort();
    ReceivePort allProgressPort = ReceivePort();

    await Isolate.spawn(
        downloading,
        IsolateOption.create(
            [infos, progressPort.sendPort, allProgressPort.sendPort]));
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

  static downloading(IsolateOption<List> option) async {
    option.init();

    DownloadInfos infos = option.argument[0];
    SendPort port = option.argument[1];
    SendPort port2 = option.argument[2];

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
            "${I18n.format("gui.download.ing")} ${widget.file.displayName.replaceAll(".jar", "")}"),
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
