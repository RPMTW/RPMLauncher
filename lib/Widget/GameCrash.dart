import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

class GameCrash_ extends State<GameCrash> {
  late String ErrorCode;
  late String ErrorLog;

  GameCrash_(ErrorCode_, ErrorLog_) {
    ErrorCode = ErrorCode_;
    ErrorLog = ErrorLog_;
  }

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return Center(
        child: AlertDialog(
      title: Text(i18n.Format("log.game.crash.title"),
          textAlign: TextAlign.center),
      content: Container(
        height: 400.0,
        width: 1000.0,
        child: ListView(
          children: [
            Text("${i18n.Format("log.game.crash.code")}: ${ErrorCode}\n",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent, fontSize: 20)),
            Text("${i18n.Format("log.game.crash.report")}:\n",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.cyanAccent, fontSize: 20)),
            Text(ErrorLog, textAlign: TextAlign.center)
          ],
        ),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.copy_outlined),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: ErrorLog));
          },
          tooltip: i18n.Format("gui.copy.clipboard"),
        ),
        IconButton(
          icon: Icon(Icons.close_sharp),
          onPressed: () {
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new LauncherHome()),
            );
          },
          tooltip: i18n.Format("gui.close"),
        )
      ],
    ));
  }
}

class GameCrash extends StatefulWidget {
  late String ErrorCode;
  late String ErrorLog;

  GameCrash(ErrorCode_, ErrorLog_) {
    ErrorCode = ErrorCode_;
    ErrorLog = ErrorLog_;
  }

  @override
  GameCrash_ createState() => GameCrash_(ErrorCode, ErrorLog);
}
