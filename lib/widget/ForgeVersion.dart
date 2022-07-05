import 'package:flutter/material.dart';
import 'package:rpmlauncher/launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/util/I18n.dart';

import 'AddInstance.dart';
import 'rwl_loading.dart';

class ForgeVersion extends StatefulWidget {
  final String instanceName;
  final MCVersion version;

  const ForgeVersion(this.instanceName, this.version);

  @override
  State<ForgeVersion> createState() => _ForgeVersionState();
}

class _ForgeVersionState extends State<ForgeVersion> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(I18n.format('version.list.mod.loader.forge.version'),
            textAlign: TextAlign.center),
        content: SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: FutureBuilder(
            future: ForgeAPI.getAllLoaderVersion(widget.version.id),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data.length,
                    itemBuilder: (BuildContext context, int index) {
                      String forgeVersionID = snapshot.data[index]
                          .toString()
                          .split("${widget.version.id}-")
                          .join("");

                      return Material(
                        child: ListTile(
                          title:
                              Text(forgeVersionID, textAlign: TextAlign.center),
                          subtitle: Builder(builder: (context) {
                            if (index == 0) {
                              return Text(
                                  I18n.format(
                                      'version.list.mod.loader.forge.version.latest'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.lightGreenAccent));
                            } else {
                              return Container();
                            }
                          }),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AddInstanceDialog(
                                  widget.instanceName,
                                  widget.version,
                                  ModLoader.forge,
                                  forgeVersionID,
                                  MinecraftSide.client),
                            );
                          },
                        ),
                      );
                    });
              } else {
                return const Center(child: RWLLoading());
              }
            },
          ),
        ));
  }
}
