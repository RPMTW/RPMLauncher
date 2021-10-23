import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Screen/Settings.dart';
import 'package:rpmlauncher/Utility/Process.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/main.dart';
import 'package:system_info/system_info.dart';

import '../Utility/RPMPath.dart';

class _DownloadJavaState extends State<DownloadJava> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: I18nText(
        "gui.tips.info",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 25),
      ),
      content: I18nText(
        "launcher.java.install.not",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
        ),
      ),
      actions: [
        Center(
            child: TextButton(
                child: I18nText("launcher.java.install.auto",
                    style: TextStyle(fontSize: 20, color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => Task(
                            javaVersions: widget.javaVersions,
                          ));
                })),
        SizedBox(
          height: 10,
        ),
        Center(
            child: TextButton(
          child: I18nText("launcher.java.install.manual",
              style: TextStyle(fontSize: 20, color: Colors.lightBlue)),
          onPressed: () {
            navigator.pop();
            navigator.pushNamed(SettingScreen.route);
          },
        )),
      ],
    );
  }
}

class DownloadJava extends StatefulWidget {
  final List<int> javaVersions;

  const DownloadJava({required this.javaVersions});

  @override
  _DownloadJavaState createState() => _DownloadJavaState();
}

class Task extends StatefulWidget {
  final List<int> javaVersions;
  const Task({required this.javaVersions});

  @override
  _TaskState createState() => _TaskState();
}

class _TaskState extends State<Task> {
  late List<double> downloadJavaProgreses;
  late List<bool> finishs;

  double get downloadProgres {
    if (finishs.every((b) => b)) return 1;
    double _p = 0.0;
    downloadJavaProgreses.forEach((progres) {
      _p += progres;
    });
    return _p / downloadJavaProgreses.length;
  }

  @override
  void initState() {
    super.initState();
    downloadJavaProgreses =
        List.generate(widget.javaVersions.length, (index) => 0);
    finishs = List.generate(widget.javaVersions.length, (index) => false);
    widget.javaVersions.forEach((int version) {
      thread(version);
    });
  }

  Future<void> thread(int version) async {
    ReceivePort port = ReceivePort();
    Isolate isolate = await Isolate.spawn(
        downloadJavaProcess, [port.sendPort, version, dataHome]);
    var exit = ReceivePort();
    isolate.addOnExitListener(exit.sendPort);
    exit.listen((message) {
      finishs[widget.javaVersions.indexOf(version)] = true;
      setState(() {});
    });
    port.listen((message) {
      setState(() {
        downloadJavaProgreses[widget.javaVersions.indexOf(version)] =
            double.parse(message.toString());
      });
    });
  }

  static downloadJavaProcess(List arguments) async {
    int totalFiles = 0;
    int doneFiles = 0;
    late Future<void> _future;

    SendPort port = arguments[0];
    int javaVersion = arguments[1];
    Directory dataHome = arguments[2];

    Response response = await get(Uri.parse(mojangJREAPI));
    Map mojangJRE = json.decode(response.body);

    Future<void> download(url) async {
      Response response = await get(Uri.parse(url));
      Map files = json.decode(response.body);
      totalFiles = files["files"].keys.length;

      files["files"].keys.forEach((String file) async {
        if (files["files"][file]["type"] == "file") {
          File jreFile = File(
              join(dataHome.absolute.path, "jre", javaVersion.toString(), file))
            ..createSync(recursive: true);
          await http
              .get(Uri.parse(files["files"][file]["downloads"]["raw"]["url"]))
              .then((response) {
            jreFile.writeAsBytesSync(response.bodyBytes);
            doneFiles++;
            port.send(doneFiles / totalFiles);
          }).timeout(Duration(milliseconds: 150), onTimeout: () {});
        } else {
          Directory(join(
                  dataHome.absolute.path, "jre", javaVersion.toString(), file))
              .createSync(recursive: true);
          doneFiles++;
          port.send(doneFiles / totalFiles);
        }
      });
    }

    switch (Platform.operatingSystem) {
      case 'linux':
        mojangJRE["linux"].keys.forEach((version) {
          if (version == "minecraft-java-exe") return;
          var versionMap = mojangJRE["linux"][version][0];
          if (versionMap["version"]["name"].contains(javaVersion.toString())) {
            _future = download(versionMap["manifest"]["url"]);
            return;
          }
        });
        break;
      case 'macos':
        mojangJRE["mac-os"].keys.forEach((version) {
          if (version == "minecraft-java-exe") return;
          var versionMap = mojangJRE["mac-os"][version][0];
          if (versionMap["version"]["name"].contains(javaVersion.toString())) {
            _future = download(versionMap["manifest"]["url"]);

            return;
          }
        });
        break;
      case 'windows':
        mojangJRE["windows-x${SysInfo.userSpaceBitness}"]
            .keys
            .forEach((version) {
          if (version == "minecraft-java-exe") return;
          var versionMap =
              mojangJRE["windows-x${SysInfo.userSpaceBitness}"][version][0];
          if (versionMap["version"]["name"].contains(javaVersion.toString())) {
            _future = download(versionMap["manifest"]["url"]);
            return;
          }
        });
        break;
      default:
        break;
    }

    await Future.sync(() => _future);
    await RPMPath.init();
    File configFile =
        File(join(RPMPath.currentConfigHome.absolute.path, 'config.json'));

    late String _execPath;

    if (Platform.isWindows) {
      _execPath = join(dataHome.absolute.path, "jre", javaVersion.toString(),
          "bin", "javaw.exe");
    } else if (Platform.isLinux) {
      _execPath = join(
          dataHome.absolute.path, "jre", javaVersion.toString(), "bin", "java");
    } else if (Platform.isMacOS) {
      _execPath = join(dataHome.absolute.path, "jre", javaVersion.toString(),
          "jre.bundle", "Contents", "Home", "bin", "java");
    }
    Config(configFile).Change("java_path_$javaVersion", _execPath);
    await chmod(_execPath);
  }

  @override
  Widget build(BuildContext context) {
    if (downloadProgres == 1) {
      return AlertDialog(
        title:
            Text(I18n.format("gui.download.done"), textAlign: TextAlign.center),
        actions: [OkClose()],
      );
    } else {
      return AlertDialog(
        title: Text(
            I18n.format("launcher.java.install.auto.downloading") + "\n",
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text((downloadProgres * 100).toStringAsFixed(2) + "%"),
            LinearProgressIndicator(
              value: downloadProgres,
            ),
          ],
        ),
      );
    }
  }
}
