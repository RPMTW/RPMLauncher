import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/model/Game/mod_info.dart';
import 'package:rpmlauncher/pages/curseforge_addon_page.dart';
import 'package:rpmlauncher/util/i18n.dart';
import 'package:rpmlauncher/pages/curseforge_mod_version.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart';

class CurseForgeModsPage extends StatefulWidget {
  final String instanceUUID;
  final Map<File, ModInfo> modInfos;

  const CurseForgeModsPage(
      {Key? key, required this.instanceUUID, required this.modInfos})
      : super(key: key);

  @override
  State<CurseForgeModsPage> createState() => _CurseForgeModsPageState();
}

class _CurseForgeModsPageState extends State<CurseForgeModsPage> {
  late final InstanceConfig config;

  @override
  void initState() {
    config = InstanceRepository.instanceConfig(widget.instanceUUID)!;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CurseForgeAddonPage(
        title: I18n.format('edit.instance.mods.download.curseforge'),
        search: I18n.format('edit.instance.mods.download.search'),
        searchHint: I18n.format('edit.instance.mods.download.search.hint'),
        notFound: I18n.format('mods.filter.notfound'),
        tapNameKey: 'edit.instance.mods.list.name',
        tapDescriptionKey: 'edit.instance.mods.list.description',
        getModList: (fitter, index, sort) =>
            RPMTWApiClient.instance.curseforgeResource.searchMods(
                game: CurseForgeGames.minecraft,
                index: index,
                pageSize: 20,
                gameVersion: config.version,
                modLoaderType:
                    CurseForgeModLoaderType.values.byName(config.loader),
                searchFilter: fitter,
                classId: 6, // Mods
                sortField: sort),
        onInstall: (curseID, mod) {
          showDialog(
            context: context,
            builder: (context) {
              return CurseForgeModVersion(
                  curseID: curseID,
                  modDir: InstanceRepository.getModRootDir(widget.instanceUUID),
                  instanceConfig: config,
                  modInfos: widget.modInfos);
            },
          );
        });
  }
}
