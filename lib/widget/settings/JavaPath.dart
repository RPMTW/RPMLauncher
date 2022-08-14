import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/Config.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/view/RowScrollView.dart';

class JavaPathWidget extends StatefulWidget {
  const JavaPathWidget({Key? key}) : super(key: key);

  @override
  State<JavaPathWidget> createState() => _JavaPathWidgetState();
}

class _JavaPathWidgetState extends State<JavaPathWidget> {
  String javaVersion = "8";
  List<String> javaVersions = ["8", "16", "17"];
  String? javaPath;

  @override
  void initState() {
    javaPath = Config.getValue("java_path_$javaVersion") ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          I18n.format("settings.java.path"),
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.lightBlue,
          ),
          textAlign: TextAlign.center,
        ),
        RowScrollView(
          child: Row(
            children: [
              const SizedBox(
                width: 12,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 6,
                child: DropdownButton<String>(
                  value: javaVersion,
                  onChanged: (String? newValue) {
                    javaVersion = newValue!;
                    javaPath = Config.getValue("java_path_$javaVersion",
                    setState(() {});
                  },
                  isExpanded: true,
                  items: javaVersions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      alignment: Alignment.center,
                      child: Text("${I18n.format("java.version")}: $value",
                          style: const TextStyle(fontSize: 20),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Text(javaPath ?? "", style: const TextStyle(fontSize: 20)),
              const SizedBox(
                width: 12,
              ),
              ElevatedButton(
                  onPressed: () {
                    Util.openJavaSelectScreen(context).then((value) {
                      if (value[0]) {
                        Config.change("java_path_$javaVersion", value[1]);
                        javaPath = Config.getValue("java_path_$javaVersion");
                        setState(() {});
                      }
                    });
                  },
                  child: Text(
                    I18n.format("settings.java.path.select"),
                    style: const TextStyle(fontSize: 18),
                  )),
              const SizedBox(
                width: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
