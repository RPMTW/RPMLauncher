import 'dart:io';

import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

class GameCrash_ extends State<GameCrash> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: AlertDialog(
      title: Text(i18n.format("log.game.crash.title"),
          textAlign: TextAlign.center),
      content: SizedBox(
        height: 400.0,
        width: 1000.0,
        child: ListView(
          children: [
            Text("${i18n.format("log.game.crash.code")}: ${widget.ErrorCode}\n",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent, fontSize: 20)),
            Text("${i18n.format("log.game.crash.report")}:\n",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.cyanAccent, fontSize: 20)),
            Text(widget.ErrorLog, textAlign: TextAlign.center)
          ],
        ),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.copy_outlined),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.ErrorLog));
          },
          tooltip: i18n.format("gui.copy.clipboard"),
        ),
        IconButton(
          icon: Icon(Icons.close_sharp),
          onPressed: () {
            if (widget.NewWindow) {
              exit(0);
            } else {
              navigator.push(PushTransitions(builder: (context) => HomePage()));
            }
          },
          tooltip: i18n.format("gui.close"),
        )
      ],
    ));
  }
}

class GameCrash extends StatefulWidget {
  final String ErrorCode;
  final String ErrorLog;
  final bool NewWindow;

  const GameCrash(
      {required this.ErrorCode,
      required this.ErrorLog,
      required this.NewWindow});

  @override
  GameCrash_ createState() => GameCrash_();
}
