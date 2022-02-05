import 'dart:io';

import 'package:rpmlauncher/Route/PushTransitions.dart';
import 'package:rpmlauncher/Screen/HomePage.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/Utility.dart';

class _GameCrashState extends State<GameCrash> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: AlertDialog(
      title: Text(I18n.format("log.game.crash.title"),
          textAlign: TextAlign.center),
      content: SizedBox(
        height: 400.0,
        width: 1000.0,
        child: ListView(
          children: [
            Text("${I18n.format("log.game.crash.code")}: ${widget.errorCode}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 20)),
            const SizedBox(height: 10),
            Text("${I18n.format("log.game.crash.report")}:",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 20)),
            const SizedBox(height: 10),
            Text(widget.errorLog, textAlign: TextAlign.center)
          ],
        ),
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.errorLog));
          },
          tooltip: I18n.format("gui.copy.clipboard"),
        ),
        IconButton(
          icon: const Icon(Icons.close_sharp),
          onPressed: () {
            if (LauncherInfo.multiWindow) {
              Uttily.closeWindow();
            } else {
              navigator.push(
                  PushTransitions(builder: (context) => const HomePage()));
            }
          },
          tooltip: I18n.format("gui.close"),
        )
      ],
    ));
  }
}

class GameCrash extends StatefulWidget {
  final int errorCode;
  final String errorLog;

  const GameCrash({
    required this.errorCode,
    required this.errorLog,
  });

  @override
  _GameCrashState createState() => _GameCrashState();
}
