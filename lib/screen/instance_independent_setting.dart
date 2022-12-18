import 'package:flutter/material.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/screen/settings.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/view/row_scroll_view.dart';
import 'package:rpmlauncher/widget/dialog/CheckDialog.dart';
import 'package:rpmlauncher/widget/memory_slider.dart';
import 'package:rpmlauncher/widget/settings/jvm_args_settings.dart';

class InstanceIndependentSetting extends StatefulWidget {
  final InstanceConfig instanceConfig;

  const InstanceIndependentSetting({Key? key, required this.instanceConfig})
      : super(key: key);

  @override
  State<InstanceIndependentSetting> createState() =>
      _InstanceIndependentSettingState();
}

class _InstanceIndependentSettingState
    extends State<InstanceIndependentSetting> {
  late TextEditingController jvmArgsController;

  late double javaMaxRam;
  late int javaVersion;
  late String? javaPath;

  @override
  void initState() {
    jvmArgsController = TextEditingController();
    javaVersion = widget.instanceConfig.javaVersion;
    javaMaxRam = widget.instanceConfig.javaMaxRam ?? launcherConfig.jvmMaxRam;
    javaPath = widget.instanceConfig.storage['java_path_$javaVersion'];

    super.initState();
  }

  @override
  void dispose() {
    jvmArgsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return ListTile(
        title: Column(children: [
      const SizedBox(
        height: 20,
      ),
      RowScrollView(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(
            child: I18nText(
              'edit.instance.settings.global',
              style: const TextStyle(fontSize: 20),
            ),
            onPressed: () {
              navigator.pushNamed(SettingScreen.route);
            },
          ),
          const SizedBox(
            width: 20,
          ),
          ElevatedButton(
            child: I18nText(
              'edit.instance.settings.reset',
              style: const TextStyle(fontSize: 18),
            ),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return CheckDialog(
                      title: I18n.format('edit.instance.settings.reset'),
                      message:
                          I18n.format('edit.instance.settings.reset.message'),
                      onPressedOK: (context) {
                        widget.instanceConfig.storage
                            .setItem('java_path_$javaVersion', null);
                        widget.instanceConfig.javaMaxRam = null;
                        widget.instanceConfig.javaJvmArgs = null;
                        javaMaxRam = launcherConfig.jvmMaxRam;
                        jvmArgsController.text = '';
                        setState(() {});
                        Navigator.pop(context);
                      },
                    );
                  });
            },
          ),
        ]),
      ),
      const SizedBox(
        height: 20,
      ),
      I18nText(
        'edit.instance.settings.title',
        style: const TextStyle(color: Colors.red, fontSize: 30),
      ),
      const SizedBox(
        height: 25,
      ),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
            ),
            Column(
              children: [
                I18nText(
                  'settings.java.path',
                  style: const TextStyle(
                    fontSize: 20.0,
                    color: Colors.lightBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(javaPath ?? I18n.format('gui.default')),
              ],
            ),
            const SizedBox(
              width: 12,
            ),
            ElevatedButton(
                onPressed: () {
                  Util.openJavaSelectScreen(context).then((value) {
                    if (value[0]) {
                      widget.instanceConfig.storage
                          .setItem('java_path_$javaVersion', value[1]);
                      javaPath = value[1];
                      setState(() {});
                    }
                  });
                },
                child: Text(
                  I18n.format('settings.java.path.select'),
                  style: const TextStyle(fontSize: 18),
                )),
          ]),
      MemorySlider(
          value: javaMaxRam,
          onChanged: (memory) {
            widget.instanceConfig.javaMaxRam = memory;
          }),
      I18nText(
        'settings.java.jvm.args',
        style: titleStyle,
        textAlign: TextAlign.center,
      ),
      JVMArgsSettings(
          value: widget.instanceConfig.javaJvmArgs ?? [],
          onChanged: (value) {
            widget.instanceConfig.javaJvmArgs = value;
          })
    ]));
  }
}
