import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/JvmArgs.dart';
import 'package:rpmlauncher/Screen/Settings.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/View/RowScrollView.dart';
import 'package:rpmlauncher/Widget/Dialog/CheckDialog.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

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

  late double nowMaxRamMB;
  late int javaVersion;
  late String? javaPath;

  @override
  void initState() {
    jvmArgsController = TextEditingController();
    javaVersion = widget.instanceConfig.javaVersion;
    nowMaxRamMB =
        widget.instanceConfig.javaMaxRam ?? Config.getValue('java_max_ram');
    javaPath = widget.instanceConfig.storage["java_path_$javaVersion"];

    List<String>? jvmArgs = widget.instanceConfig.javaJvmArgs;
    if (jvmArgs != null) {
      jvmArgsController.text = JvmArgs.fromList(jvmArgs).args;
    } else {
      jvmArgsController.text = "";
    }

    super.initState();
  }

  @override
  void dispose() {
    jvmArgsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle _title = TextStyle(
      fontSize: 20.0,
      color: Colors.lightBlue,
    );

    return ListTile(
        title: Column(children: [
      SizedBox(
        height: 20,
      ),
      RowScrollView(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(
            child: I18nText(
              "edit.instance.settings.global",
              style: TextStyle(fontSize: 20),
            ),
            onPressed: () {
              navigator.pushNamed(SettingScreen.route);
            },
          ),
          SizedBox(
            width: 20,
          ),
          ElevatedButton(
            child: I18nText(
              "edit.instance.settings.reset",
              style: TextStyle(fontSize: 18),
            ),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return CheckDialog(
                      title: I18n.format('edit.instance.settings.reset'),
                      message:
                          I18n.format('edit.instance.settings.reset.message'),
                      onPressedOK: () {
                        widget.instanceConfig.storage
                            .removeItem("java_path_$javaVersion");
                        widget.instanceConfig.javaMaxRam = null;
                        widget.instanceConfig.javaJvmArgs = null;
                        nowMaxRamMB = Config.getValue('java_max_ram');
                        jvmArgsController.text = "";
                        setState(() {});
                        Navigator.pop(context);
                      },
                    );
                  });
            },
          ),
        ]),
      ),
      SizedBox(
        height: 20,
      ),
      I18nText(
        "edit.instance.settings.title",
        style: TextStyle(color: Colors.red, fontSize: 30),
      ),
      SizedBox(
        height: 25,
      ),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
            ),
            Column(
              children: [
                I18nText(
                  "settings.java.path",
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.lightBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(javaPath ?? I18n.format("gui.default")),
              ],
            ),
            SizedBox(
              width: 12,
            ),
            ElevatedButton(
                onPressed: () {
                  Uttily.openJavaSelectScreen(context).then((value) {
                    if (value[0]) {
                      widget.instanceConfig.storage
                          .setItem("java_path_$javaVersion", value[1]);
                      javaPath = value[1];
                      setState(() {});
                    }
                  });
                },
                child: Text(
                  I18n.format("settings.java.path.select"),
                  style: TextStyle(fontSize: 18),
                )),
          ]),
      FutureBuilder<int>(
          future: Uttily.getTotalPhysicalMemory(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              double ramMB = snapshot.data!.toDouble();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    I18n.format("settings.java.ram.max"),
                    style: _title,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "${I18n.format("settings.java.ram.physical")} ${ramMB.toStringAsFixed(0)} MB",
                  ),
                  Slider(
                    value: nowMaxRamMB,
                    onChanged: (double value) {
                      widget.instanceConfig.javaMaxRam = value;
                      nowMaxRamMB = value;
                      setState(() {});
                    },
                    min: 1024,
                    max: ramMB,
                    divisions: (ramMB ~/ 1024) - 1,
                    label: "${nowMaxRamMB.toInt()} MB",
                  ),
                ],
              );
            } else {
              return RWLLoading();
            }
          }),
      Text(
        I18n.format('settings.java.jvm.args'),
        style: _title,
        textAlign: TextAlign.center,
      ),
      ListTile(
        title: RPMTextField(
          textAlign: TextAlign.center,
          controller: jvmArgsController,
          onChanged: (value) async {
            widget.instanceConfig.javaJvmArgs = JvmArgs(args: value).toList();
            setState(() {});
          },
        ),
      ),
    ]));
  }
}
