import 'dart:io';

import 'package:rpmlauncher/Screen/HomePage.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';

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
                style: TextStyle(color: Colors.redAccent, fontSize: 20)),
            SizedBox(height: 10),
            Text("${I18n.format("log.game.crash.report")}:",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.cyanAccent, fontSize: 20)),
            SizedBox(height: 10),
            Text(widget.errorLog, textAlign: TextAlign.center)
          ],
        ),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.copy_outlined),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.errorLog));
          },
          tooltip: I18n.format("gui.copy.clipboard"),
        ),
        IconButton(
          icon: Icon(Icons.close_sharp),
          onPressed: () {
            if (widget.newWindow) {
              exit(0);
            } else {
              navigator.push(PushTransitions(builder: (context) => HomePage()));
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
  final bool newWindow;

  const GameCrash(
      {required this.errorCode,
      required this.errorLog,
      required this.newWindow});

  @override
  _GameCrashState createState() => _GameCrashState();
}
