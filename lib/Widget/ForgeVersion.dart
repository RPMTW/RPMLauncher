import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

import 'AddInstance.dart';
import 'RWLLoading.dart';

class ForgeVersion extends StatelessWidget {
  final Color borderColour;
  final TextEditingController nameController;
  final MCVersion version;

  const ForgeVersion(this.borderColour, this.nameController, this.version);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(I18n.format('version.list.mod.loader.forge.version'),
            textAlign: TextAlign.center),
        content: SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: FutureBuilder(
            future: ForgeAPI.getAllLoaderVersion(version.id),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data.length,
                    itemBuilder: (BuildContext context, int index) {
                      String forgeVersionID = snapshot.data[index]
                          .toString()
                          .split("${version.id}-")
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
                                  style: TextStyle(
                                      color: Colors.lightGreenAccent));
                            } else {
                              return Container();
                            }
                          }),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AddInstanceDialog(
                                borderColour,
                                nameController,
                                version,
                                ModLoaders.forge,
                                forgeVersionID,
                              ),
                            );
                          },
                        ),
                      );
                    });
              } else {
                return Center(child: RWLLoading());
              }
            },
          ),
        ));
  }
}
