import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/config.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/view/RowScrollView.dart';

class JavaPathWidget extends StatefulWidget {
  const JavaPathWidget({Key? key}) : super(key: key);

  @override
  State<JavaPathWidget> createState() => _JavaPathWidgetState();
}

class _JavaPathWidgetState extends State<JavaPathWidget> {
  final List<int> javaVersions = [8, 16, 17];

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
        for (final int version in javaVersions) _JavaVersion(version: version)
      ],
    );
  }
}

class _JavaVersion extends StatefulWidget {
  final int version;

  const _JavaVersion({Key? key, required this.version}) : super(key: key);

  @override
  State<_JavaVersion> createState() => _JavaVersionState();
}

class _JavaVersionState extends State<_JavaVersion> {
  late String? javaPath;

  @override
  void initState() {
    javaPath = Config.getValue("java_path_${widget.version}");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RowScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Text('Java ${widget.version}',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              javaPath != null
                  ? Text(javaPath!, style: const TextStyle(fontSize: 16))
                  : I18nText('settings.java.path.unset',
                      style: const TextStyle(
                          color: Colors.orangeAccent, fontSize: 16)),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () {
                    Util.openJavaSelectScreen(context).then((value) {
                      if (value[0]) {
                        Config.change("java_path_${widget.version}", value[1]);
                        javaPath =
                            Config.getValue("java_path_${widget.version}");
                        setState(() {});
                      }
                    });
                  },
                  child: Text(I18n.format("settings.java.path.select"))),
            ],
          ),
        ),
      ),
    );
  }
}
