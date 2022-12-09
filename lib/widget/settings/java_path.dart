import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/view/row_scroll_view.dart';

class JavaPathSettings extends StatefulWidget {
  const JavaPathSettings({Key? key}) : super(key: key);

  @override
  State<JavaPathSettings> createState() => _JavaPathSettingsState();
}

class _JavaPathSettingsState extends State<JavaPathSettings> {
  final List<int> javaVersions = [8, 16, 17];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    javaPath = ConfigHelper.get<String>('java_path_${widget.version}');
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
                        ConfigHelper.set<String>(
                            'java_path_${widget.version}', value[1]);
                        javaPath = ConfigHelper.get<String>(
                            'java_path_${widget.version}');
                        setState(() {});
                      }
                    });
                  },
                  child: Text(I18n.format('settings.java.path.select'))),
            ],
          ),
        ),
      ),
    );
  }
}
