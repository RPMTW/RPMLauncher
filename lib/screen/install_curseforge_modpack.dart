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
  late TextEditingController nameController;

  @override
  void initState() {
    nameController = TextEditingController();

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
                            return _InstallTask(
                              meta: snapshot.data!,
                              versionID: versionID,
                              instanceName: nameController.text,
                              manifest: widget.manifest,
                              archive: widget.archive,
                              iconUrl: widget.iconUrl,
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

class _InstallTask extends StatefulWidget {
  final MinecraftMeta meta;
  final String versionID;
  final String instanceName;
  final Map manifest;
  final Archive archive;
  final String? iconUrl;

  const _InstallTask({
    required this.meta,
    required this.versionID,
    required this.manifest,
    required this.instanceName,
    required this.archive,
    required this.iconUrl,
  });

  @override
  State<_InstallTask> createState() => _InstallTaskState();
}

class _InstallTaskState extends State<_InstallTask> {
  @override
  void initState() {
    super.initState();
    installingState.finish = false;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final String loaderID =
          widget.manifest['minecraft']['modLoaders'][0]['id'];

      final ModLoader loader;
      if (loaderID.startsWith(ModLoader.fabric.name)) {
        loader = ModLoader.fabric;
      } else {
        loader = ModLoader.forge;
      }

      final String loaderVersion = loaderID.split('${loader.name}-').join('');
      final String uuid = const Uuid().v4();

      final InstanceConfig config = InstanceConfig(
          uuid: uuid,
          name: widget.instanceName,
          side: MinecraftSide.client,
          version: widget.versionID,
          loader: loader.name,
          javaVersion: widget.meta.javaVersion,
          loaderVersion: loaderVersion,
          assetsID: widget.meta['assets']);

      config.createConfigFile();

      if (widget.iconUrl != null) {
        // Download the icon file of the modpack
        String path =
            join(GameRepository.getInstanceRootDir().path, uuid, 'icon.png');
        await RPMHttpClient().download(widget.iconUrl!, path);
      }

      Util.javaCheckDialog(
          hasJava: () => CurseModPackClient.createClient(
              setState: setState,
              meta: widget.meta,
              versionID: widget.versionID,
              loaderVersion: loaderVersion,
              instanceUUID: uuid,
              manifest: widget.manifest,
              archive: widget.archive),
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
