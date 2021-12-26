import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Launcher/InstanceRepository.dart';
import 'package:rpmlauncher/Mod/CurseForge/Handler.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Model/Game/RecommendedModpack.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/RPMHttpClient.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/View/RowScrollView.dart';
import 'package:rpmlauncher/Widget/AddInstance.dart';
import 'package:rpmlauncher/Widget/RPMNetworkImage.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/Widget/WIPWidget.dart';
import 'package:rpmlauncher/Widget/CurseForgeModVersion.dart'
    as curseforge_version;
import 'package:rpmlauncher/Utility/Data.dart';

class RecommendedModpackScreen extends StatefulWidget {
  const RecommendedModpackScreen({Key? key}) : super(key: key);

  @override
  _RecommendedModpackScreenState createState() =>
      _RecommendedModpackScreenState();
}

class _RecommendedModpackScreenState extends State<RecommendedModpackScreen> {
  Future<RecommendedModpacks> get() async {
    Response response = await RPMHttpClient().get(recommendedModpack);

    return RecommendedModpacks.fromList(
        RPMHttpClient.json(response.data).cast<Map<String, dynamic>>());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecommendedModpacks>(
      future: get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          RecommendedModpacks modpacks = snapshot.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              I18nText(
                "version.recommended_modpack.title",
                style: TextStyle(fontSize: 35, color: Colors.yellow[700]),
              ),
              SizedBox(
                height: 15,
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: modpacks.length,
                    itemBuilder: (BuildContext context, int index) {
                      RecommendedModpack modpack = modpacks[index];

                      return Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                  child: RPMNetworkImage(
                                      src: modpack.image,
                                      width: 450,
                                      height: 250)),
                              Expanded(
                                child: ListTile(
                                  title: Text(modpack.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 35)),
                                  subtitle: Text(modpack.description,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 20)),
                                ),
                              ),
                              _OptionWidget(modpack: modpack)
                            ],
                          ),
                          Divider()
                        ],
                      );
                    }),
              ),
            ],
          );
        } else {
          return RWLLoading(logo: true);
        }
      },
    );
  }
}

class _OptionWidget extends StatelessWidget {
  const _OptionWidget({
    Key? key,
    required this.modpack,
  }) : super(key: key);

  final RecommendedModpack modpack;

  @override
  Widget build(BuildContext context) {
    List<Widget> rowWidget = [
      ElevatedButton.icon(
          onPressed: () {
            if (modpack.type == RecommendedModpackType.instance) {
              showDialog(
                context: context,
                builder: (context) => InstanceTask(modpack: modpack),
              );
            } else if (modpack.type ==
                RecommendedModpackType.curseforgeModpack) {
              showDialog(context: context, builder: (context) => WiPWidget());
            }
          },
          icon: Icon(Icons.download),
          label: I18nText("gui.install")),
      SizedBox(
        width: 20,
      ),
    ];

    if (modpack.link != null) {
      rowWidget.addAll([
        ElevatedButton.icon(
            onPressed: () => Uttily.openUri(modpack.link!),
            icon: Icon(Icons.link),
            label: I18nText("version.recommended_modpack.link")),
        SizedBox(width: 20)
      ]);
    }

    return RowScrollView(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: rowWidget,
      ),
    );
  }
}

class InstanceTask extends StatelessWidget {
  const InstanceTask({
    Key? key,
    required this.modpack,
  }) : super(key: key);

  final RecommendedModpack modpack;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MCVersionManifest>(
      future: MCVersionManifest.vanilla(),
      builder:
          (BuildContext context, AsyncSnapshot<MCVersionManifest> snapshot) {
        if (snapshot.hasData) {
          return AddInstanceDialog(
            modpack.name,
            snapshot.data!.versions.firstWhere(
                (version) => version.comparableVersion == modpack.version),
            modpack.loader,
            modpack.loaderVersion,
            MinecraftSide.client,
            onInstalled: (instance) {
              return Future.sync(() async {
                await RPMHttpClient()
                    .download(modpack.image, join(instance.path, "icon.png"));

                if (modpack.mods != null) {
                  for (Map mod in modpack.mods!) {
                    int curseforgeID = mod['curseforgeID'];

                    List<Map>? fileInfos =
                        await CurseForgeHandler.getAddonFilesByVersion(
                            curseforgeID,
                            instance.config.version,
                            instance.config.loaderEnum,
                            ignoreCheck: true);

                    if (fileInfos == null) {
                      continue;
                    }

                    await showDialog(
                        context: navigator.context,
                        builder: (context) => curseforge_version.Task(
                            fileInfos.first,
                            InstanceRepository.getModRootDir(instance.uuid),
                            instance.config.version,
                            instance.config.loaderEnum,
                            autoClose: true));
                  }
                }
              });
            },
          );
        } else {
          return RWLLoading();
        }
      },
    );
  }
}
