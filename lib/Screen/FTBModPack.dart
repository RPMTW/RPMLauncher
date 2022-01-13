import 'package:dio/dio.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/InstallingState.dart';
import 'package:rpmlauncher/Mod/FTB/Handler.dart';
import 'package:rpmlauncher/Mod/FTB/ModPackClient.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Route/PushTransitions.dart';
import 'package:rpmlauncher/Screen/HomePage.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/RPMHttpClient.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/View/RowScrollView.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:uuid/uuid.dart';

import 'package:rpmlauncher/Utility/Data.dart';

class _FTBModPackState extends State<FTBModPack> {
  TextEditingController searchController = TextEditingController();
  ScrollController modPackScrollController = ScrollController();

  List<String> versionItems = [];
  String versionItem = I18n.format('modpack.all_version');

  @override
  void dispose() {
    searchController.dispose();
    modPackScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          I18nText("modpack.ftb.title", textAlign: TextAlign.center),
          SizedBox(
            height: 20,
          ),
          RowScrollView(
            child: Row(
              children: [
                Text(I18n.format('modpack.search')),
                SizedBox(
                  width: 12,
                ),
                SizedBox(
                  width: 500,
                  child: RPMTextField(
                    textAlign: TextAlign.center,
                    controller: searchController,
                    hintText: I18n.format('modpack.search.hint'),
                  ),
                ),
                SizedBox(
                  width: 12,
                ),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.deepPurpleAccent)),
                  onPressed: () {
                    setState(() {});
                  },
                  child: Text(I18n.format("gui.search")),
                ),
                SizedBox(
                  width: 12,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(I18n.format("game.version")),
                    FutureBuilder(
                        future: FTBHandler.getVersions(),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            versionItems = [I18n.format('modpack.all_version')];
                            versionItems.addAll(snapshot.data);

                            return DropdownButton<String>(
                              value: versionItem,
                              onChanged: (String? newValue) {
                                setState(() {
                                  versionItem = newValue!;
                                });
                              },
                              items: versionItems.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }).toList(),
                            );
                          } else {
                            return Center(child: RWLLoading());
                          }
                        })
                  ],
                ),
              ],
            ),
          )
        ],
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: FutureBuilder(
            future: FTBHandler.getModPackList(),
            builder: (context, AsyncSnapshot<List> snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.isEmpty) {
                  return Text(I18n.format('modpack.found'),
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center);
                }

                return ListView.builder(
                  controller: modPackScrollController,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return FutureBuilder<Response>(
                        future: RPMHttpClient().get(
                            "$ftbModPackAPI/modpack/${snapshot.data![index]}"),
                        builder:
                            (context, AsyncSnapshot<Response> modpackSnapshot) {
                          if (modpackSnapshot.hasData) {
                            Map data =
                                RPMHttpClient.json(modpackSnapshot.data!.data);

                            if (data['status'] == 'error') {
                              return Container();
                            }

                            bool versionCkeck = versionItem ==
                                    I18n.format('modpack.all_version')
                                ? true
                                : (data['tags'] == null
                                    ? false
                                    : (data['tags'].any((tag) => tag['name']
                                        .toString()
                                        .contains(versionItem))));

                            bool nameSearchCheck =
                                searchController.text.isNotEmpty
                                    ? data['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(
                                            searchController.text.toLowerCase())
                                    : true;

                            String name = data["name"];
                            String modDescription = data["synopsis"];
                            String url = FTBHandler.getWebUrlFromName(name);
                            int modpackID = data["id"];

                            if (versionCkeck && nameSearchCheck) {
                              return ListTile(
                                leading: Image.network(
                                  data["art"][0]["url"],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded
                                                      .toInt() /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                                      .toInt()
                                              : null,
                                    );
                                  },
                                ),
                                title: Text(name),
                                subtitle: Text(modDescription),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        onPressed: () => Uttily.openUri(url),
                                        tooltip: I18n.format(
                                            'edit.instance.mods.page.open'),
                                        icon: Icon(Icons.open_in_browser)),
                                    SizedBox(width: 12),
                                    ElevatedButton(
                                      child: Text(I18n.format("gui.install")),
                                      onPressed: () {
                                        List versions = data['versions'];
                                        versions.sort((a, b) => a['updated']);
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(I18n.format(
                                                  "edit.instance.mods.download.select.version")),
                                              content: SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      3,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      3,
                                                  child: ListView.builder(
                                                      itemCount:
                                                          versions.length,
                                                      itemBuilder: (BuildContext
                                                              context,
                                                          int versionsIndex) {
                                                        return FutureBuilder(
                                                            future: FTBHandler
                                                                .getVersionInfo(
                                                                    modpackID,
                                                                    versions[
                                                                            versionsIndex]
                                                                        ["id"]),
                                                            builder: (context,
                                                                AsyncSnapshot
                                                                    snapshot) {
                                                              if (snapshot
                                                                  .hasData) {
                                                                Map versionInfo =
                                                                    snapshot
                                                                        .data;
                                                                return ListTile(
                                                                  title: Text(
                                                                      versionInfo[
                                                                          "name"]),
                                                                  subtitle: FTBHandler
                                                                      .parseReleaseType(
                                                                          versionInfo[
                                                                              "type"]),
                                                                  onTap: () {
                                                                    showDialog(
                                                                      barrierDismissible:
                                                                          false,
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (context) =>
                                                                              AddFTBModpack(
                                                                        versionInfo:
                                                                            versionInfo,
                                                                        packData:
                                                                            data,
                                                                      ),
                                                                    );
                                                                  },
                                                                );
                                                              } else {
                                                                return Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    RWLLoading()
                                                                  ],
                                                                );
                                                              }
                                                            });
                                                      })),
                                              actions: <Widget>[
                                                IconButton(
                                                  icon: Icon(Icons.close_sharp),
                                                  tooltip:
                                                      I18n.format("gui.close"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: I18nText(
                                          'modpack.name',
                                          args: {"name": name},
                                        ),
                                        content: I18nText(
                                          'modpack.description',
                                          args: {"description": modDescription},
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            } else {
                              return Container();
                            }
                          } else {
                            return ListTile(title: Center(child: RWLLoading()));
                          }
                        });
                  },
                );
              } else {
                return Center(child: RWLLoading());
              }
            }),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.close_sharp),
          tooltip: I18n.format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class FTBModPack extends StatefulWidget {
  @override
  _FTBModPackState createState() => _FTBModPackState();
}

class AddFTBModpack extends StatefulWidget {
  final Map versionInfo;
  final Map packData;

  const AddFTBModpack({required this.versionInfo, required this.packData});

  @override
  _AddFTBModpackState createState() => _AddFTBModpackState();
}

class _AddFTBModpackState extends State<AddFTBModpack> {
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    nameController.text = widget.packData["name"];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: I18nText("modpack.add.title", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(I18n.format("edit.instance.homepage.instance.name"),
                  style: TextStyle(fontSize: 18, color: Colors.amberAccent)),
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
          SizedBox(
            height: 12,
          ),
          I18nText(
            'modpack.name',
            args: {"name": widget.packData["name"]},
          ),
          I18nText(
            'modpack.version',
            args: {"version": widget.versionInfo["name"]},
          ),
          I18nText(
            'modpack.version.game',
            args: {"game_version": widget.versionInfo["targets"][1]["version"]},
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text(I18n.format("gui.cancel")),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: Text(I18n.format("gui.confirm")),
            onPressed: () {
              navigator.pop();
              navigator.push(PushTransitions(builder: (context) => HomePage()));

              String versionID = widget.versionInfo["targets"][1]["version"];

              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return FutureBuilder(
                        future: Uttily.getVanillaVersionMeta(versionID),
                        builder: (BuildContext context,
                            AsyncSnapshot<MinecraftMeta> snapshot) {
                          if (snapshot.hasData) {
                            return Task(
                                meta: snapshot.data!,
                                versionInfo: widget.versionInfo,
                                packData: widget.packData,
                                instanceName: nameController.text,
                                versionID: versionID);
                          } else {
                            return Center(child: RWLLoading());
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
  final Map versionInfo;
  final Map packData;
  final String instanceName;
  final String versionID;

  const Task(
      {Key? key,
      required this.meta,
      required this.versionInfo,
      required this.packData,
      required this.instanceName,
      required this.versionID})
      : super(key: key);

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  @override
  void initState() {
    installingState.finish = false;
    installingState.nowEvent = I18n.format('version.list.downloading.ready');

    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      String uuid = Uuid().v4();

      String loaderID = widget.versionInfo["targets"][0]["name"];
      bool isFabric = loaderID.startsWith(ModLoader.fabric.fixedString);
      String loaderVersionID = widget.versionInfo["targets"][0]["version"];

      InstanceConfig config = InstanceConfig(
          uuid: uuid,
          name: widget.instanceName,
          side: MinecraftSide.client,
          version: widget.versionID,
          loader: (isFabric ? ModLoader.fabric : ModLoader.forge).fixedString,
          javaVersion: widget.meta.javaVersion,
          loaderVersion: loaderVersionID,
          assetsID: widget.meta["assets"]);

      config.createConfigFile();

      await RPMHttpClient().download(
          widget.packData['art'][0]['url'],
          join(GameRepository.getInstanceRootDir().absolute.path,
              widget.instanceName, "icon.png"));

      Uttily.javaCheckDialog(
          hasJava: () => FTBModPackClient.createClient(
              instanceUUID: uuid,
              meta: widget.meta,
              versionInfo: widget.versionInfo,
              packData: widget.packData,
              setState: setState),
          allJavaVersions: config.needJavaVersion);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (installingState.finish &&
        installingState.downloadInfos.progress == 1.0) {
      return AlertDialog(
        title: Text(I18n.format("gui.download.done")),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(I18n.format("gui.close")))
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
                  "${(installingState.downloadInfos.progress * 100).toStringAsFixed(2)}%")
            ],
          ),
        ),
      );
    }
  }
}
