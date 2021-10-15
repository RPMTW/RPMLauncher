import 'dart:io';

import 'package:rpmlauncher/Screen/DownloadCurseModPack.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

class CurseModPackHandler {
  static Future<Archive> UnZip(File File) async {
    return ZipDecoder().decodeBytes(await (File.readAsBytes()));
  }

  static Widget Setup(File ModPackZipFile, [String ModPackIconUrl = ""]) {
    try {
      return FutureBuilder(
          future: UnZip(ModPackZipFile),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              final Archive archive = snapshot.data;
              bool isModPack =
                  archive.files.any((file) => file.name == "manifest.json");
              if (isModPack) {
                return WillPopScope(
                  onWillPop: () => Future.value(false),
                  child: DownloadCurseModPack(archive, ModPackIconUrl),
                );
              } else {
                return AlertDialog(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(i18n.format("gui.error.info")),
                    content: Text("錯誤的模組包格式"),
                    actions: <Widget>[
                      TextButton(
                        child: Text(i18n.format("gui.ok")),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      )
                    ]);
              }
            } else {
              return AlertDialog(
                  title: Text("正在解析模組包資訊中..."),
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
