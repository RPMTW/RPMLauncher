import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/mod/curseforge/ModPackHandler.dart';
import 'package:rpmlauncher/mod/curseforge/curseforge_handler.dart';
import 'package:rpmlauncher/model/IO/isolate_option.dart';
import 'package:rpmlauncher/pages/curseforge_addon_page.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/widget/RWLLoading.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart';

class CurseForgeModpackPage extends StatefulWidget {
  const CurseForgeModpackPage({Key? key}) : super(key: key);

  @override
  State<CurseForgeModpackPage> createState() => _CurseForgeModpackPageState();
}

class _CurseForgeModpackPageState extends State<CurseForgeModpackPage> {
  String? fitterVersion;

  @override
  Widget build(BuildContext context) {
    return CurseForgeAddonPage(
        title: I18n.format('modpack.curseforge.title'),
        search: I18n.format('modpack.search'),
        searchHint: I18n.format('modpack.search.hint'),
        notFound: I18n.format('modpack.found'),
        tapNameKey: 'modpack.name',
        tapDescriptionKey: 'modpack.description',
        getModList: (fitter, index, sort) =>
            RPMTWApiClient.instance.curseforgeResource.searchMods(
                game: CurseForgeGames.minecraft,
                index: index,
                pageSize: 20,
                gameVersion: fitterVersion,
                searchFilter: fitter,
                classId: 4471, // Modpack
                sortField: sort),
        onInstall: (curseID, mod) {
          List<CurseForgeModLatestFile> files =
              mod.latestFiles.reversed.toList();

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(
                    I18n.format("edit.instance.mods.download.select.version")),
                content: SizedBox(
                    height: MediaQuery.of(context).size.height / 3,
                    width: MediaQuery.of(context).size.width / 3,
                    child: ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        CurseForgeModLatestFile file = files[index];

                        if (fitterVersion != null &&
                            !file.gameVersions.any((_) => _ == fitterVersion)) {
                          return Container();
                        } else {
                          return ListTile(
                            title:
                                Text(file.displayName.replaceAll(".zip", "")),
                            subtitle: CurseForgeHandler.parseReleaseType(
                                file.releaseType),
                            onTap: () {
                              showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context) =>
                                      Task(file, mod.logo?.url));
                            },
                          );
                        }
                      },
                    )),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close_sharp),
                    tooltip: I18n.format("gui.close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        fitterOptions: (cleanAllMods) => [
              _FitterOptions(cleanAllMods, (version) {
                setState(() {
                  fitterVersion = version;
                });
              })
            ]);
  }
}

class _FitterOptions extends StatefulWidget {
  final VoidCallback cleanAllMods;
  final ValueChanged<String?> onChanged;
  const _FitterOptions(this.cleanAllMods, this.onChanged, {Key? key})
      : super(key: key);

  @override
  State<_FitterOptions> createState() => _FitterOptionsState();
}

class _FitterOptionsState extends State<_FitterOptions> {
  String defaultVersion = I18n.format('modpack.all_version');

  late final List<String> versionItems;
  late String versionItem;

  @override
  void initState() {
    versionItems = [defaultVersion];
    versionItem = defaultVersion;

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final versions = await RPMTWApiClient.instance.curseforgeResource
          .getMinecraftVersions();
      versionItems.addAll(versions.map((e) => e.versionString).toList());
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(I18n.format("game.version")),
          Builder(builder: (context) {
            if (versionItems.length == 1) {
              return const Center(child: RWLLoading());
            } else {
              return DropdownButton<String>(
                value: versionItem,
                onChanged: (String? newValue) {
                  setState(() {
                    versionItem = newValue!;
                    widget.cleanAllMods();

                    if (versionItem == defaultVersion) {
                      widget.onChanged(null);
                    } else {
                      widget.onChanged(versionItem);
                    }
                  });
                },
                items:
                    versionItems.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              );
            }
          })
        ],
      )
    ]);
  }
}

class Task extends StatefulWidget {
  final CurseForgeModLatestFile file;
  final String? modPackIconUrl;

  const Task(this.file, this.modPackIconUrl);

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  late File modPackFile;
  @override
  void initState() {
    super.initState();
    modPackFile =
        File(join(Directory.systemTemp.absolute.path, widget.file.fileName));
    thread(widget.file.downloadUrl);
  }

  static double _progress = 0;

  thread(url) async {
    ReceivePort port = ReceivePort();
    await Isolate.spawn(
        downloading, IsolateOption.create([url, modPackFile], ports: [port]));
    port.listen((message) {
      setState(() {
        _progress = message;
      });
    });
  }

  static downloading(IsolateOption<List> option) async {
    option.init();

    String url = option.argument[0];
    File packFile = option.argument[1];
    await RPMHttpClient().download(url, packFile.path,
        onReceiveProgress: (rec, total) {
      option.sendData(rec / total);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1.0) {
      return CurseModPackHandler.setup(modPackFile, widget.modPackIconUrl);
    } else {
      return AlertDialog(
        title: Text(I18n.format('modpack.downloading')),
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
