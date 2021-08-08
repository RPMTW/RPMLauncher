import 'package:RPMLauncher/MCLauncher/Fabric/FabricAPI.dart';
import 'package:RPMLauncher/Utility/ModLoader.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'AddInstance.dart';

FabricVersion(
    BorderColour, NameController, InstanceDir, Data, ModLoaderName, context) {
  return AlertDialog(
      title: Text("請選擇您要安裝的 Fabric Loader 版本", textAlign: TextAlign.center),
      content: Container(
        height: MediaQuery.of(context).size.height / 3,
        width: MediaQuery.of(context).size.width / 3,
        child: FutureBuilder(
          future: FabricAPI().GetLoaderVersions(Data["id"]),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    Map FabricMeta = snapshot.data[index];
                    late Text SubtitleText;
                    bool IsStable = FabricMeta["loader"]["stable"];
                    if (IsStable) {
                      SubtitleText = Text(
                          i18n.Format("edit.instance.mods.release"),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.lightBlue));
                    } else {
                      SubtitleText = Text(
                          i18n.Format("edit.instance.mods.beta"),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red));
                    }

                    return Material(
                      child: ListTile(
                        title: Text(FabricMeta["loader"]["version"],
                            textAlign: TextAlign.center),
                        subtitle: SubtitleText,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddInstanceDialog(
                                BorderColour,
                                InstanceDir,
                                NameController,
                                Data,
                                ModLoader().Fabric,
                                FabricMeta["loader"]["version"]),
                          );
                        },
                      ),
                    );
                  });
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ));
}
