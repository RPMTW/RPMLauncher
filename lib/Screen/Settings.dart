import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/Game/JvmArgs.dart';
import 'package:rpmlauncher/Model/UI/ViewOptions.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/RPMPath.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/View/OptionsView.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/RPMTextField.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/Widget/Settings/JavaPath.dart';

class _SettingScreenState extends State<SettingScreen> {
  Color get primaryColor => ThemeUtility.getTheme().colorScheme.primary;

  TextEditingController jvmArgsController = TextEditingController();
  TextEditingController gameWidthController = TextEditingController();
  TextEditingController gameHeightController = TextEditingController();
  TextEditingController wrapperCommandController = TextEditingController();
  TextEditingController maxLogLengthController = TextEditingController();

  late bool autoJava;
  late bool checkAssets;
  late bool showLog;
  late bool autoDependencies;
  late bool autoFullScreen;
  late bool validateAccount;
  late bool autoCloseLogScreen;
  late bool discordRichPresence;

  String? backgroundPath;
  double nowMaxRamMB = Config.getValue("java_max_ram");

  VersionTypes updateChannel =
      Updater.getVersionTypeFromString(Config.getValue('update_channel'));

  int selectedIndex = 0;

  @override
  void initState() {
    autoJava = Config.getValue("auto_java");
    validateAccount = Config.getValue("validate_account");
    autoCloseLogScreen = Config.getValue("auto_close_log_screen");
    checkAssets = Config.getValue("check_assets");
    showLog = Config.getValue("show_log");
    autoDependencies = Config.getValue("auto_dependencies");
    autoFullScreen = LauncherInfo.autoFullScreen;
    discordRichPresence = Config.getValue("discord_rpc");

    gameWidthController.text = Config.getValue("game_width").toString();
    gameHeightController.text = Config.getValue("game_height").toString();
    maxLogLengthController.text = Config.getValue("max_log_length").toString();
    wrapperCommandController.text = Config.getValue("wrapper_command") ?? "";
    jvmArgsController.text =
        JvmArgs.fromList(Config.getValue("java_jvm_args")).args;
    super.initState();
  }

  TextStyle title_ = const TextStyle(
    fontSize: 20.0,
    color: Colors.lightBlue,
  );

  @override
  void dispose() {
    jvmArgsController.dispose();
    gameWidthController.dispose();
    gameHeightController.dispose();
    wrapperCommandController.dispose();
    maxLogLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(I18n.format("settings.title")),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: I18n.format("gui.back"),
            onPressed: () {
              navigator.pop();
            },
          ),
        ),
        body: OptionsView(
          gripSize: 3,
          optionWidgets: (StateSetter _setState) {
            return [
              ListView(
                children: [
                  const JavaPathWidget(),
                  const Divider(),
                  SwitchListTile(
                    value: autoJava,
                    onChanged: (value) {
                      _setState(() {
                        autoJava = !autoJava;
                        Config.change("auto_java", autoJava);
                      });
                    },
                    title: Text(
                      I18n.format("settings.java.auto"),
                      style: title_,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(),
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
                                style: title_,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                "${I18n.format("settings.java.ram.physical")} ${ramMB.toStringAsFixed(0)} MB",
                              ),
                              Slider(
                                value: nowMaxRamMB,
                                onChanged: (double value) {
                                  Config.change("java_max_ram", value);
                                  nowMaxRamMB = value;
                                  _setState(() {});
                                },
                                activeColor: primaryColor,
                                min: 1024,
                                max: ramMB,
                                divisions: (ramMB ~/ 1024) - 1,
                                label: "${nowMaxRamMB.toInt()} MB",
                              ),
                            ],
                          );
                        } else {
                          return const RWLLoading();
                        }
                      }),
                  const Divider(),
                  Text(
                    I18n.format('settings.java.jvm.args'),
                    style: title_,
                    textAlign: TextAlign.center,
                  ),
                  ListTile(
                    title: RPMTextField(
                      textAlign: TextAlign.center,
                      controller: jvmArgsController,
                      onChanged: (value) {
                        Config.change(
                            'java_jvm_args', JvmArgs(args: value).toList());
                        _setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              ListView(
                children: [
                  Column(
                    children: [
                      SelectorLanguageWidget(setWidgetState: _setState),
                      const Divider(),
                      Text(
                        I18n.format("settings.appearance.theme"),
                        style: title_,
                      ),
                      SelectorThemeWidget(
                        themeString: ThemeUtility.toI18nString(
                            ThemeUtility.getThemeEnumByConfig()),
                        setWidgetState: _setState,
                      ),
                      const Divider(),
                      Text(
                        I18n.format("settings.appearance.background.title"),
                        style: title_,
                      ),
                      Text(backgroundPath ?? I18n.format("gui.default"),
                          style: const TextStyle(fontSize: 18),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                              onPressed: () async {
                                final result = await FilePicker.platform
                                    .pickFiles(type: FileType.image);
                                if (result != null) {
                                  PlatformFile file = result.files.single;
                                  Config.change('background', file.path);
                                  backgroundPath = file.path;
                                }
                                setState(() {});
                              },
                              child: Text(I18n.format(
                                  "settings.appearance.background.pick"))),
                          const SizedBox(width: 10),
                          ElevatedButton(
                              onPressed: () {
                                Config.change('background', "");
                                backgroundPath = null;
                                setState(() {});
                              },
                              child: Text(I18n.format(
                                  "settings.appearance.background.reset"))),
                        ],
                      ),
                      const Divider(),
                      Text(
                        I18n.format("settings.appearance.window.size.title"),
                        style: title_,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: RPMTextField(
                              textAlign: TextAlign.center,
                              controller: gameWidthController,
                              verify: (value) => int.tryParse(value) != null,
                              hintText: "854",
                              onChanged: (value) async {
                                Config.change("game_width", int.parse(value));
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          const Icon(Icons.clear),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: RPMTextField(
                              textAlign: TextAlign.center,
                              controller: gameHeightController,
                              hintText: "480",
                              verify: (value) => int.tryParse(value) != null,
                              onChanged: (value) async {
                                Config.change("game_height", int.parse(value));
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
              ListView(
                controller: ScrollController(),
                children: [
                  I18nText("settings.advanced.tips",
                      style: const TextStyle(color: Colors.red, fontSize: 30),
                      textAlign: TextAlign.center),
                  const Divider(),
                  ListTile(
                    title:
                        I18nText("settings.advanced.datahome", style: title_),
                    subtitle: SelectableText(
                        RPMPath.currentDataHome.absolute.path,
                        style: const TextStyle(fontSize: 20)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                            onPressed: () async {
                              String? path =
                                  await FilePicker.platform.getDirectoryPath();

                              if (path != null) {
                                Config.change("data_home", path);
                                _setState(() {});
                                showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) =>
                                        const _ChangeDataHomeSuccessful());
                              }
                            },
                            icon: const Icon(Icons.folder),
                            label:
                                I18nText("settings.advanced.datahome.change")),
                        const SizedBox(
                          width: 12,
                        ),
                        ElevatedButton.icon(
                            onPressed: () {
                              Config.change(
                                  "data_home", RPMPath.defaultDataHome.path);
                              _setState(() {});
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) =>
                                      const _ChangeDataHomeSuccessful());
                            },
                            icon: const Icon(Icons.restore),
                            label:
                                I18nText("settings.advanced.datahome.restore"))
                      ],
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: checkAssets,
                    onChanged: (value) {
                      _setState(() {
                        checkAssets = !checkAssets;
                        Config.change("check_assets", checkAssets);
                      });
                    },
                    title: I18nText("settings.advanced.assets.check",
                        style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: showLog,
                    onChanged: (value) {
                      _setState(() {
                        showLog = !showLog;
                        Config.change("show_log", showLog);
                      });
                    },
                    title:
                        I18nText("settings.advanced.show_log", style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: autoDependencies,
                    onChanged: (value) {
                      _setState(() {
                        autoDependencies = !autoDependencies;
                        Config.change("auto_dependencies", autoDependencies);
                      });
                    },
                    title: I18nText("settings.advanced.auto_dependencies",
                        style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: autoFullScreen,
                    onChanged: (value) {
                      _setState(() {
                        autoFullScreen = !autoFullScreen;
                        Config.change("auto_full_screen", autoFullScreen);
                      });
                    },
                    title: I18nText("settings.advanced.auto_full_screen",
                        style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: validateAccount,
                    onChanged: (value) {
                      _setState(() {
                        validateAccount = !validateAccount;
                        Config.change("validate_account", validateAccount);
                      });
                    },
                    title: I18nText("settings.advanced.validate_account",
                        style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: autoCloseLogScreen,
                    onChanged: (value) {
                      _setState(() {
                        autoCloseLogScreen = !autoCloseLogScreen;
                        Config.change(
                            "auto_close_log_screen", autoCloseLogScreen);
                      });
                    },
                    title: I18nText("settings.advanced.auto_close_log_screen",
                        style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: discordRichPresence,
                    onChanged: (value) {
                      _setState(() {
                        discordRichPresence = !discordRichPresence;
                        Config.change("discord_rpc", discordRichPresence);
                      });
                    },
                    title: I18nText("settings.advanced.discord_rpc",
                        style: title_),
                  ),
                  const Divider(),
                  ListTile(
                    title: I18nText("settings.advanced.update_channel",
                        style: title_),
                    trailing: StatefulBuilder(builder: (context, _setState) {
                      return DropdownButton(
                          value: updateChannel,
                          items: [
                            DropdownMenuItem(
                              value: VersionTypes.stable,
                              child: Text(
                                  Updater.toI18nString(VersionTypes.stable)),
                            ),
                            DropdownMenuItem(
                              value: VersionTypes.dev,
                              child:
                                  Text(Updater.toI18nString(VersionTypes.dev)),
                            ),
                          ],
                          onChanged: (dynamic channel) async {
                            _setState(() {
                              updateChannel = channel;
                              Config.change('update_channel',
                                  Updater.toStringFromVersionType(channel));
                            });
                          });
                    }),
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 12,
                  ),
                  ListTile(
                    title: I18nText("settings.advanced.max.log", style: title_),
                    trailing: SizedBox(
                      width: 600,
                      child: RPMTextField(
                        textAlign: TextAlign.center,
                        controller: maxLogLengthController,
                        verify: (value) => int.tryParse(value) != null,
                        hintText: "300",
                        onChanged: (value) async {
                          Config.change("max_log_length", int.parse(value));
                        },
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: I18nText("settings.advanced.wrapper_command",
                        style: title_),
                    trailing: SizedBox(
                      width: 600,
                      child: RPMTextField(
                        textAlign: TextAlign.center,
                        controller: wrapperCommandController,
                        hintText: "Executable program",
                        onChanged: (value) {
                          Config.change(
                              "wrapper_command", value.isEmpty ? null : value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              ListView(
                children: [
                  I18nText("settings.advanced.tips",
                      style: const TextStyle(color: Colors.red, fontSize: 30),
                      textAlign: TextAlign.center),
                  const SizedBox(
                    height: 12,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                          onPressed: () {
                            dataHome.deleteSync(recursive: true);
                            exit(0);
                          },
                          child: I18nText("settings.debug.delete_all_data",
                              style: title_)),
                    ],
                  ),
                ],
              ),
            ];
          },
          options: () {
            return ViewOptions([
              ViewOptionTile(
                title: I18n.format("settings.java.title"),
                icon: const Icon(
                  Icons.code_outlined,
                ),
              ),
              ViewOptionTile(
                title: I18n.format("settings.appearance.title"),
                icon: const Icon(
                  Icons.web_asset_outlined,
                ),
              ),
              ViewOptionTile(
                title: I18n.format("settings.advanced.title"),
                icon: const Icon(
                  Icons.settings,
                ),
              ),
              ViewOptionTile(
                title: I18n.format('settings.debug.title'),
                icon: const Icon(
                  Icons.bug_report,
                ),
              )
            ]);
          },
        ));
  }
}

class _ChangeDataHomeSuccessful extends StatelessWidget {
  const _ChangeDataHomeSuccessful({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: I18nText("settings.advanced.datahome.change.successful"),
      actions: [
        OkClose(
          onOk: () {
            exit(0);
          },
        )
      ],
    );
  }
}

class SettingScreen extends StatefulWidget {
  static const String route = "/settings";

  @override
  _SettingScreenState createState() => _SettingScreenState();
}
