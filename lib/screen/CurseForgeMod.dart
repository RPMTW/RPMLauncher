import 'dart:io';

import 'package:rpmlauncher/launcher/InstanceRepository.dart';
import 'package:rpmlauncher/mod/CurseForge/handler.dart';
import 'package:rpmlauncher/model/Game/Instance.dart';
import 'package:rpmlauncher/model/Game/mod_info.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/widget/CurseForgeModVersion.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/widget/rpmtw_design/RPMTextField.dart';
import 'package:rpmlauncher/widget/RWLLoading.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart';

class _CurseForgeModPageState extends State<CurseForgeModPage> {
  late TextEditingController searchController;
  late ScrollController modScrollController;

  List<CurseForgeMod> beforeModList = [];
  bool isReset = true;
  int index = 20;

  Directory get modDir => InstanceRepository.getModRootDir(widget.instanceUUID);
  late InstanceConfig instanceConfig;
  List<CurseForgeSortField> sortItems = [
    CurseForgeSortField.featured,
    CurseForgeSortField.popularity,
    CurseForgeSortField.lastUpdated,
    CurseForgeSortField.name,
    CurseForgeSortField.author,
    CurseForgeSortField.totalDownloads
  ];
  CurseForgeSortField sortItem = CurseForgeSortField.popularity;

  @override
  void initState() {
    searchController = TextEditingController();
    modScrollController = ScrollController();
    instanceConfig = InstanceRepository.instanceConfig(widget.instanceUUID)!;

    super.initState();

    modScrollController.addListener(() {
      if ((modScrollController.position.maxScrollExtent -
              modScrollController.position.pixels) <
          50) {
        //如果快要滑動到底部
        index = index + 20;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text(I18n.format('edit.instance.mods.download.curseforge'),
              textAlign: TextAlign.center),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(I18n.format('edit.instance.mods.download.search')),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                  child: RPMTextField(
                textAlign: TextAlign.center,
                controller: searchController,
                hintText:
                    I18n.format('edit.instance.mods.download.search.hint'),
              )),
              const SizedBox(
                width: 12,
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.deepPurpleAccent)),
                onPressed: () {
                  setState(() {
                    isReset = true;
                    beforeModList = [];
                  });
                },
                child: Text(I18n.format('gui.search')),
              ),
              const SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(I18n.format('edit.instance.mods.sort')),
                  DropdownButton<CurseForgeSortField>(
                    value: sortItem,
                    onChanged: (CurseForgeSortField? newValue) {
                      setState(() {
                        sortItem = newValue!;
                        isReset = true;
                        beforeModList = [];
                      });
                    },
                    items: sortItems.map<DropdownMenuItem<CurseForgeSortField>>(
                        (CurseForgeSortField value) {
                      return DropdownMenuItem<CurseForgeSortField>(
                        value: value,
                        child: Text(
                          I18n.format(
                              'edit.instance.mods.sort.curseforge.${value.name}'),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder<List<CurseForgeMod>>(
            future: CurseForgeHandler.getModList(
                instanceConfig.version,
                instanceConfig.loader,
                searchController,
                beforeModList,
                isReset ? 0 : index,
                sortItem),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                isReset = false;
                if (snapshot.data!.isEmpty) {
                  return I18nText('mods.filter.notfound',
                      style: const TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                }
                beforeModList = snapshot.data!;
                return ListView.builder(
                  controller: modScrollController,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    CurseForgeMod mod = snapshot.data![index];
                    String modName = mod.name;
                    String modDescription = mod.summary;
                    int curseID = mod.id;
                    String pageUrl = mod.links.websiteUrl;
                    
                    return ListTile(
                      leading: CurseForgeHandler.getAddonIconWidget(mod.logo),
                      title: Text(modName),
                      subtitle: Text(modDescription),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              Util.openUri(pageUrl);
                            },
                            icon: const Icon(Icons.open_in_browser),
                            tooltip:
                                I18n.format('edit.instance.mods.page.open'),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return CurseForgeModVersion(
                                    curseID: curseID,
                                    modDir: modDir,
                                    instanceConfig: instanceConfig,
                                    modInfos: widget.modInfos,
                                  );
                                },
                              );
                            },
                            child: Text(I18n.format('gui.install')),
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                  I18n.format('edit.instance.mods.list.name') +
                                      modName,
                                  textAlign: TextAlign.center),
                              content: Text(
                                  I18n.format(
                                          'edit.instance.mods.list.description') +
                                      modDescription,
                                  textAlign: TextAlign.center),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              } else {
                return const Center(child: RWLLoading());
              }
            }),
      ),
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

class CurseForgeModPage extends StatefulWidget {
  final String instanceUUID;
  final Map<File, ModInfo> modInfos;

  const CurseForgeModPage(this.instanceUUID, this.modInfos);
  @override
  State<CurseForgeModPage> createState() => _CurseForgeModPageState();
}
