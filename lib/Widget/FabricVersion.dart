import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

import 'AddInstance.dart';
import 'RWLLoading.dart';

class FabricVersion extends StatelessWidget {
  final String instanceName;
  final MCVersion version;

  const FabricVersion(this.instanceName, this.version);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(I18n.format("version.list.mod.loader.fabric.version"),
            textAlign: TextAlign.center),
        content: SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: FutureBuilder(
            future: FabricAPI().getLoaderVersions(version.id),
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
                            I18n.format("edit.instance.mods.release"),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.lightBlue));
                      } else {
                        subtitleText = Text(
                            I18n.format("edit.instance.mods.beta"),
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
                                instanceName,
                                version,
                                ModLoader.fabric,
                                fabricMeta["loader"]["version"],
                                MinecraftSide.client,
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
