import 'dart:io';
import 'dart:isolate';

import 'package:RPMLauncher/Mod/CurseForge/Handler.dart';
import 'package:RPMLauncher/Utility/Config.dart';
import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';

class DownloadCurseModPack extends StatefulWidget {
  late List Args;

  DownloadCurseModPack(List Args_) {
    Args = Args_;
  }

  @override
  DownloadCurseModPack_ createState() => DownloadCurseModPack_(Args);
}

class DownloadCurseModPack_ extends State<DownloadCurseModPack> {
  late List Args;

  DownloadCurseModPack_(Args_) {
    Args = Args_;
  }

  @override
  void initState() {
    super.initState();


  }

  static double _progress = 0;
  static int downloadedLength = 0;
  static int contentLength = 0;

  Thread(url, ModFile) async {
    var port = ReceivePort();
    var isolate = await Isolate.spawn(Downloading, [url, ModFile, port.sendPort]);
    var exit = ReceivePort();
    isolate.addOnExitListener(exit.sendPort);
    exit.listen((message) {
      if (message == null) {
        // A null message means the isolate exited
      }
    });
    port.listen((message) {
      setState(() {
        _progress = message;
      });
    });
  }

  static Downloading(List args) async {
    String url = args[0];
    File ModFile = args[1];
    SendPort port = args[2];
    final request = Request('GET', Uri.parse(url));
    final StreamedResponse response = await Client().send(request);
    contentLength += response.contentLength!;
    List<int> bytes = [];
    response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        downloadedLength += newBytes.length;
        port.send(downloadedLength / contentLength);
      },
      onDone: () async {
        await ModFile.writeAsBytes(bytes);
      },
      onError: (e) {
        print(e);
      },
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_progress == 1) {
      return AlertDialog(
        title: Text(i18n.Format("gui.download.done")),
        actions: <Widget>[
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(i18n.Format("gui.close")))
        ],
      );
    } else {
      return AlertDialog(
        title: Text("正在下載模組包中..."),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${(_progress * 100).toStringAsFixed(3)}%"),
            LinearProgressIndicator(value: _progress)
          ],
        ),
      );
    }
  }
}
