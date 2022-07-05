import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/mod/curseforge/curseforge_handler.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/pages/curseforge_modpack_page.dart';
import 'package:rpmlauncher/screen/FTBModPack.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/screen/RecommendedModpackScreen.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/theme.dart';
import 'package:rpmlauncher/widget/dialog/UnSupportedForgeVersion.dart';
import 'package:rpmlauncher/widget/RWLLoading.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:split_view/split_view.dart';

import 'package:rpmlauncher/util/data.dart';
import 'DownloadGameDialog.dart';

class VersionSelection extends StatefulWidget {
  final MinecraftSide side;

  const VersionSelection({Key? key, required this.side}) : super(key: key);

  @override
  State<VersionSelection> createState() => _VersionSelectionState();
}

class _VersionSelectionState extends State<VersionSelection> {
  int _selectedIndex = 0;
  bool showRelease = true;
  bool showSnapshot = false;
  bool versionManifestLoading = true;
  TextEditingController versionSearchController = TextEditingController();

  String modLoaderName = I18n.format("version.list.mod.loader.vanilla");
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    versionSearchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _widgetOptions = <Widget>[
      SplitView(
        gripSize: 3,
        controller: SplitViewController(weights: [0.83]),
        viewMode: SplitViewMode.Horizontal,
        children: [
          FutureBuilder(
              future: MCVersionManifest.formLoaderType(
                  ModLoaderUttily.getByI18nString(modLoaderName)),
              builder: (BuildContext context,
                  AsyncSnapshot<MCVersionManifest> snapshot) {
                versionManifestLoading =
                    snapshot.connectionState != ConnectionState.done;

                if (!versionManifestLoading && snapshot.hasData) {
                  List<MCVersion> versions = snapshot.data!.versions;
                  List<MCVersion> formattedVersions = [];
                  formattedVersions = versions.where((version) {
                    bool inputVersionID =
                        version.id.contains(versionSearchController.text);
                    switch (version.type.name) {
                      case "release":
                        return showRelease && inputVersionID;
                      case "snapshot":
                        return showSnapshot && inputVersionID;
                      default:
                        return false;
                    }
                  }).toList();

                  return ListView.builder(
                      itemCount: formattedVersions.length,
                      itemBuilder: (context, index) {
                        final MCVersion version = formattedVersions[index];
                        return ListTile(
                          title: Text(version.id),
                          onTap: () {
                            ModLoader loader =
                                ModLoaderUttily.getByI18nString(modLoaderName);

                            // TODO: 支援啟動 Forge 遠古版本
                            if (loader == ModLoader.forge &&
                                version.comparableVersion < Version(1, 7, 0)) {
                              showDialog(
                                  context: context,
                                  builder: (context) => UnSupportedForgeVersion(
                                      gameVersion: version.id));
                            } else {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return DownloadGameDialog(
                                        "${loader.name.toCapitalized()}-${version.id}",
                                        version,
                                        loader,
                                        widget.side);
                                  });
                            }
                          },
                        );
                      });
                } else if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                } else {
                  return const Center(child: RWLLoading());
                }
              }),
          Column(
            children: [
              const SizedBox(height: 10),
              SizedBox(
                height: 45,
                width: 200,
                child: TextField(
                  controller: versionSearchController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: I18n.format("version.list.filter"),
                  ),
                  onEditingComplete: () {
                    setState(() {});
                  },
                ),
              ),
              Text(
                I18n.format("version.list.mod.loader"),
                style: const TextStyle(
                    fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 100,
                child: DropdownButton<String>(
                  value: modLoaderName,
                  style: const TextStyle(color: Colors.lightBlue),
                  onChanged: (String? value) {
                    setState(() {
                      modLoaderName = value!;
                    });
                  },
                  isExpanded: true,
                  items: ModLoader.values
                      .where((e) =>
                          e.supportInstall() &&
                          e.supportedSides().any((e) => e == widget.side))
                      .map((e) => e.i18nString)
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      alignment: Alignment.center,
                      child: Text(value,
                          style: const TextStyle(
                              fontSize: 17.5, fontFamily: 'font'),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ),
              ),
              Text(
                I18n.format("version.list.type"),
                style: const TextStyle(
                    fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      showRelease = value!;
                    });
                  },
                  value: showRelease,
                ),
                title: Text(
                  I18n.format("version.list.show.release"),
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                leading: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      showSnapshot = value!;
                    });
                  },
                  value: showSnapshot,
                ),
                title: Text(
                  I18n.format("version.list.show.snapshot"),
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ListView(
        children: [
          Text(I18n.format('modpack.install'),
              style: const TextStyle(fontSize: 30, color: Colors.lightBlue),
              textAlign: TextAlign.center),
          Text(I18n.format('modpack.source'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20)),
          const SizedBox(
            height: 12,
          ),
          Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.asset("assets/images/CurseForge.png")),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(I18n.format('modpack.from.curseforge'),
                        style: const TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) => const CurseForgeModpackPage());
                },
              ),
              const SizedBox(
                height: 12,
              ),
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.asset("assets/images/FTB.png")),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(I18n.format('modpack.from.ftb'),
                        style: const TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () {
                  showDialog(
                      context: context, builder: (context) => FTBModPack());
                },
              ),
              const SizedBox(
                height: 12,
              ),
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.computer,
                      size: 60,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(I18n.format('modpack.import'),
                        style: const TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () async {
                  final FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                          dialogTitle: I18n.format('modpack.file'),
                          type: FileType.custom,
                          allowedExtensions: [
                        'zip',
                      ]);

                  if (result == null) {
                    return;
                  }
                  File file = File(result.files.single.path!);

                  showDialog(
                      context: context,
                      builder: (context) =>
                          CurseForgeHandler.installModpack(file));
                },
              ),
            ],
          ))
        ],
      ),
      const RecommendedModpackScreen()
    ];
    return Scaffold(
      appBar: AppBar(
        title: I18nText("version.list.instance.type"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: I18n.format("gui.back"),
          onPressed: () {
            navigator.pop();
          },
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: widget.side == MinecraftSide.client
          ? NavigationBar(
              destinations: [
                NavigationDestination(
                    icon: SizedBox(
                        width: 30,
                        height: 30,
                        child: Image.asset("assets/images/Minecraft.png")),
                    label: 'Minecraft',
                    tooltip: ""),
                NavigationDestination(
                    icon: const SizedBox(
                        width: 30, height: 30, child: Icon(Icons.folder)),
                    label: I18n.format('modpack.title'),
                    tooltip: ""),
                NavigationDestination(
                    icon: const SizedBox(
                        width: 30, height: 30, child: Icon(Icons.reviews)),
                    tooltip: "",
                    label: I18n.format('version.recommended_modpack.title')),
              ],
              selectedIndex: _selectedIndex,
              backgroundColor:
                  ThemeUtility.getThemeEnumByConfig() == Themes.dark
                      ? Colors.black12.withAlpha(15)
                      : null,
              onDestinationSelected: _onItemTapped,
            )
          : SizedBox(
              height: 60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Theme.of(context).colorScheme.background,
                          width: 0.2)),
                ),
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                            width: 30,
                            height: 30,
                            child: Image.asset("assets/images/Minecraft.png")),
                        const Text('Minecraft'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
