import 'package:rpmlauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

import 'AddInstance.dart';

ForgeVersion(BorderColour, NameController, Data, ModLoaderName, context) {
  return AlertDialog(
      title: Text(i18n.Format('version.list.mod.loader.forge.version'),
          textAlign: TextAlign.center),
      content: Container(
        height: MediaQuery.of(context).size.height / 3,
        width: MediaQuery.of(context).size.width / 3,
        child: FutureBuilder(
          future: ForgeAPI.getAllLoaderVersion(Data["id"]),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    String ForgeVersionID = snapshot.data[index]
                        .toString()
                        .split("${Data["id"]}-")
                        .join("");

                    return Material(
                      child: ListTile(
                        title:
                            Text(ForgeVersionID, textAlign: TextAlign.center),
                        subtitle: Builder(builder: (context) {
                          if (index == 0) {
                            return Text(
                                i18n.Format(
                                    'version.list.mod.loader.forge.version.latest'),
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: Colors.lightGreenAccent));
                          } else {
                            return Container();
                          }
                        }),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddInstanceDialog(
                              BorderColour,
                              NameController,
                              Data,
                              ModLoader().Forge,
                              ForgeVersionID,
                            ),
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
