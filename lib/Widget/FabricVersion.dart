import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

import 'AddInstance.dart';
import 'RWLLoading.dart';

class FabricVersion extends StatelessWidget {
  final Color borderColour;
  final TextEditingController nameController;
  final Map metaData;

  const FabricVersion(this.borderColour, this.nameController, this.metaData);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(i18n.format("version.list.mod.loader.fabric.version"),
            textAlign: TextAlign.center),
        content: SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: FutureBuilder(
            future: FabricAPI().getLoaderVersions(metaData["id"]),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data.length,
                    itemBuilder: (BuildContext context, int index) {
                      Map fabricMeta = snapshot.data[index];
                      late Text subtitleText;
                      bool isStable = fabricMeta["loader"]["stable"];
                      if (isStable) {
                        subtitleText = Text(
                            i18n.format("edit.instance.mods.release"),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.lightBlue));
                      } else {
                        subtitleText = Text(
                            i18n.format("edit.instance.mods.beta"),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red));
                      }

                      return Material(
                        child: ListTile(
                          title: Text(fabricMeta["loader"]["version"],
                              textAlign: TextAlign.center),
                          subtitle: subtitleText,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AddInstanceDialog(
                                borderColour,
                                nameController,
                                metaData,
                                ModLoaders.fabric,
                                fabricMeta["loader"]["version"],
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
