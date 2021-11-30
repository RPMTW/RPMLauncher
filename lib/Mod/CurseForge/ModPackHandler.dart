import 'dart:io';

import 'package:rpmlauncher/Screen/DownloadCurseModPack.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

class CurseModPackHandler {
  static Future<Archive> unZip(File file) async {
    return ZipDecoder().decodeBytes(await (file.readAsBytes()));
  }

  static Widget setup(File modPackZipFile, [String modPackIconUrl = ""]) {
    try {
      return FutureBuilder(
          future: unZip(modPackZipFile),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              final Archive archive = snapshot.data;
              bool isModPack =
                  archive.files.any((file) => file.name == "manifest.json");
              if (isModPack) {
                return WillPopScope(
                  onWillPop: () => Future.value(false),
                  child: DownloadCurseModPack(archive, modPackIconUrl),
                );
              } else {
                return AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(I18n.format("gui.error.info")),
                    content: I18nText("modpack.error.format"),
                    actions: [
                      TextButton(
                        child: Text(I18n.format("gui.ok")),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      )
                    ]);
              }
            } else {
              return AlertDialog(
                  title: I18nText("modpack.parsing"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RWLLoading(),
                    ],
                  ));
            }
          });
    } on FormatException {
      return RWLLoading();
    }
  }
}
