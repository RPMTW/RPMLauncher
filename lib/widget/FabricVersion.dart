import 'package:flutter/material.dart';
import 'package:rpmlauncher/launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/util/i18n.dart';

import 'AddInstance.dart';
import 'rwl_loading.dart';

class FabricVersion extends StatelessWidget {
  final String instanceName;
  final MCVersion version;
  final MinecraftSide side;

  const FabricVersion(this.instanceName, this.version, this.side);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(I18n.format("version.list.mod.loader.fabric.version"),
            textAlign: TextAlign.center),
        content: SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
          child: FutureBuilder(
            future: FabricAPI.getLoaderVersions(version.id),
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
                            style: const TextStyle(color: Colors.lightBlue));
                      } else {
                        subtitleText = Text(
                            I18n.format("edit.instance.mods.beta"),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red));
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
                                side,
                              ),
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
