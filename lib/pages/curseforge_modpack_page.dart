import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/mod/curseforge/curseforge_handler.dart';
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
                                      _DownloadModpack(file, mod.logo?.url));
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

class _DownloadModpack extends StatefulWidget {
  final CurseForgeModLatestFile file;
  final String? iconUrl;

  const _DownloadModpack(this.file, this.iconUrl);

  @override
  State<_DownloadModpack> createState() => _DownloadModpackState();
}

class _DownloadModpackState extends State<_DownloadModpack> {
  late File modpackFile;

  @override
  void initState() {
    modpackFile =
        File(join(Directory.systemTemp.absolute.path, widget.file.fileName));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
        stream: download(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CurseForgeHandler.installModpack(
                modpackFile, widget.iconUrl);
          } else {
            final double progress = snapshot.data ?? 0.0;

            return AlertDialog(
              title: Text(I18n.format('modpack.downloading')),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${(progress * 100).toStringAsFixed(3)}%"),
                  LinearProgressIndicator(value: progress)
                ],
              ),
            );
          }
        });
  }

  Stream<double> download() async* {
    yield* Stream.multi((p0) async {
      await RPMHttpClient().download(widget.file.downloadUrl, modpackFile.path,
          onReceiveProgress: (rec, total) {
        p0.add(rec / total);
      });
      p0.close();
    });
  }
}
