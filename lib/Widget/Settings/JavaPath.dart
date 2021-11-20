import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/View/RowScrollView.dart';

class JavaPathWidget extends StatefulWidget {
  const JavaPathWidget({Key? key}) : super(key: key);

  @override
  _JavaPathWidgetState createState() => _JavaPathWidgetState();
}

class _JavaPathWidgetState extends State<JavaPathWidget> {
  String javaVersion = "8";
  List<String> javaVersions = ["8", "16", "17"];
  late String javaPath;

  @override
  void initState() {
    javaPath = Config.getValue("java_path_$javaVersion");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          I18n.format("settings.java.path"),
          style: TextStyle(
            fontSize: 20.0,
            color: Colors.lightBlue,
          ),
          textAlign: TextAlign.center,
        ),
        RowScrollView(
          child: Row(
            children: [
              SizedBox(
                width: 12,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 6,
                child: DropdownButton<String>(
                  value: javaVersion,
                  onChanged: (String? newValue) {
                    setState(() {
                      javaVersion = newValue!;
                      javaPath = Config.getValue("java_path_$javaVersion");
                    });
                  },
                  isExpanded: true,
                  items: javaVersions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      alignment: Alignment.center,
                      child: Text("${I18n.format("java.version")}: $value",
                          style: TextStyle(fontSize: 20),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Text(javaPath, style: TextStyle(fontSize: 20)),
              SizedBox(
                width: 12,
              ),
              ElevatedButton(
                  onPressed: () {
                    Uttily.openJavaSelectScreen(context).then((value) {
                      if (value[0]) {
                        Config.change("java_path_$javaVersion", value[1]);
                        javaPath = Config.getValue("java_path_$javaVersion");
                      }
                    });
                  },
                  child: Text(
                    I18n.format("settings.java.path.select"),
                    style: TextStyle(fontSize: 18),
                  )),
              SizedBox(
                width: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
