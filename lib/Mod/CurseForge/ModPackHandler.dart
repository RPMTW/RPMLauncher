import 'dart:io';

import 'package:rpmlauncher/Screen/DownloadCurseModPack.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/Utility/Data.dart';

class CurseModPackHandler {
  static Future<Archive?> unZip(File file) async {
    try {
      return ZipDecoder().decodeBytes(await (file.readAsBytes()));
    } catch (e) {
      return null;
    }
  }

  static Widget setup(File modPackZipFile, [String modPackIconUrl = ""]) {
    Widget error = AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(I18n.format("gui.error.info")),
        content: I18nText("modpack.error.format"),
        actions: [
          TextButton(
            child: Text(I18n.format("gui.ok")),
            onPressed: () {
              Navigator.pop(navigator.context);
            },
          )
        ]);

    try {
      return FutureBuilder<Archive?>(
          future: unZip(modPackZipFile),
          builder: (context, AsyncSnapshot<Archive?> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              final Archive? archive = snapshot.data;
              if (archive == null) {
                return error;
              }
              bool isModPack =
                  archive.files.any((file) => file.name == "manifest.json");
              if (isModPack) {
                return WillPopScope(
                  onWillPop: () => Future.value(false),
                  child: DownloadCurseModPack(archive, modPackIconUrl),
                );
              } else {
                return error;
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
