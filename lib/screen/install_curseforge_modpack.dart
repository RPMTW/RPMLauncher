import 'dart:convert';

import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/launcher/InstallingState.dart';
import 'package:rpmlauncher/mod/curseforge/ModPackClient.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/route/PushTransitions.dart';
import 'package:rpmlauncher/screen/home_page.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/widget/rpmtw_design/RPMTextField.dart';
import 'package:rpmlauncher/widget/RWLLoading.dart';
import 'package:uuid/uuid.dart';

import 'package:rpmlauncher/util/data.dart';

class InstallCurseForgeModpack extends StatefulWidget {
  final Map manifest;
  final Archive archive;
  final String? iconUrl;

  const InstallCurseForgeModpack(
      {required this.manifest, required this.archive, this.iconUrl});

  @override
  State<InstallCurseForgeModpack> createState() =>
      _InstallCurseForgeModpackState();
}

class _InstallCurseForgeModpackState extends State<InstallCurseForgeModpack> {
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    nameController.text = widget.manifest['name'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: I18nText('modpack.add.title', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(I18n.format('edit.instance.homepage.instance.name'),
                  style:
                      const TextStyle(fontSize: 18, color: Colors.amberAccent)),
              Expanded(
                child: RPMTextField(
                  controller: nameController,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              )
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          I18nText(
            'modpack.name',
            args: {'name': widget.manifest['name']},
          ),
          I18nText(
            'modpack.version',
            args: {
              'version':
                  widget.manifest['version'] ?? I18n.format('gui.unknown')
            },
          ),
          I18nText(
            'modpack.version.game',
            args: {'game_version': widget.manifest['minecraft']['version']},
          ),
          I18nText(
            'modpack.author',
            args: {
              'author': widget.manifest['author'] ?? I18n.format('gui.unknown')
            },
          )
        ],
      ),
      actions: [
        TextButton(
          child: Text(I18n.format('gui.cancel')),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: Text(I18n.format('gui.confirm')),
            onPressed: () async {
              navigator.push(
                  PushTransitions(builder: (context) => const HomePage()));

              String versionID = widget.manifest['minecraft']['version'];

              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return FutureBuilder<MinecraftMeta>(
                        future: Util.getVanillaVersionMeta(versionID),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Task(
                              meta: snapshot.data!,
                              versionID: versionID,
                              instanceName: nameController.text,
                              packMeta: widget.manifest,
                              packArchive: widget.archive,
                              modpackIconUrl: widget.iconUrl,
                            );
                          } else if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          } else {
                            return const Center(child: RWLLoading());
                          }
                        });
                  });
            })
      ],
    );
  }
}

class Task extends StatefulWidget {
  final MinecraftMeta meta;
  final String versionID;
  final String instanceName;
  final Map packMeta;
  final Archive packArchive;
  final String? modpackIconUrl;

  const Task({
    required this.meta,
    required this.versionID,
    required this.packMeta,
    required this.instanceName,
    required this.packArchive,
    required this.modpackIconUrl,
  });

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  @override
  void initState() {
    super.initState();
    installingState.finish = false;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      String loaderID = widget.packMeta['minecraft']['modLoaders'][0]['id'];
      bool isFabric = loaderID.startsWith(ModLoader.fabric.name);
      String loaderVersionID = loaderID
          .split('${isFabric ? ModLoader.fabric.name : ModLoader.forge.name}-')
          .join('');

      String uuid = const Uuid().v4();

      InstanceConfig config = InstanceConfig(
          uuid: uuid,
          name: widget.instanceName,
          side: MinecraftSide.client,
          version: widget.versionID,
          loader: (isFabric ? ModLoader.fabric : ModLoader.forge).name,
          javaVersion: widget.meta.javaVersion,
          loaderVersion: loaderVersionID,
          assetsID: widget.meta['assets']);

      config.createConfigFile();

      if (widget.modpackIconUrl != null) {
        await RPMHttpClient().download(widget.modpackIconUrl!,
            join(GameRepository.getInstanceRootDir().path, uuid, 'icon.png'));
      }

      Util.javaCheckDialog(
          hasJava: () => CurseModPackClient.createClient(
              setState: setState,
              meta: widget.meta,
              versionID: widget.versionID,
              loaderVersion: loaderVersionID,
              instanceUUID: uuid,
              packMeta: widget.packMeta,
              packArchive: widget.packArchive),
          allJavaVersions: config.needJavaVersion);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (installingState.finish &&
        installingState.downloadInfos.progress == 1.0) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(I18n.format('gui.download.done')),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(I18n.format('gui.close')))
        ],
      );
    } else {
      return WillPopScope(
        onWillPop: () => Future.value(false),
        child: AlertDialog(
          title: Text(installingState.nowEvent, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: installingState.downloadInfos.progress,
              ),
              Text(
                  '${(installingState.downloadInfos.progress * 100).toStringAsFixed(2)}%')
            ],
          ),
        ),
      );
    }
  }
}
