import 'dart:io';

import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:RPMLauncher/Widget/DownloadCurseModPack.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

class CurseModPackHandler {
  static Widget Setup(File ModPackZipFile) {
          return FutureBuilder(
              future: ModPackZipFile.readAsBytes(),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  final archive = ZipDecoder().decodeBytes(snapshot.data);
                  bool isModPack =
                      archive.files.any((file) => file.name == "manifest.json");
                  if (isModPack) {
                    return WillPopScope(
                      onWillPop: () => Future.value(false),
                      child: DownloadCurseModPack(archive),
                    );
                  } else {
                    return WillPopScope(
                      onWillPop: () => Future.value(false),
                      child: AlertDialog(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(i18n.Format("gui.error.info")),
                          content: Text("錯誤的模組包格式"),
                          actions: <Widget>[
                            TextButton(
                              child: Text(i18n.Format("gui.ok")),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            )
                          ]),
                    );
                  }
                } else {
                  return AlertDialog(
                    title: Text("正在解析模組包資訊中..."),
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [CircularProgressIndicator()],
                    ),
                  );
                }
        });
  }
}
