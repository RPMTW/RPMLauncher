import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/language_selector.dart';
import 'package:rpmlauncher/model/Game/JvmArgs.dart';
import 'package:rpmlauncher/model/UI/ViewOptions.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/launcher_path.dart';
import 'package:rpmlauncher/util/theme.dart';
import 'package:rpmlauncher/util/updater.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/view/OptionsView.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';
import 'package:rpmlauncher/widget/rpmtw_design/RPMTextField.dart';
import 'package:rpmlauncher/widget/settings/java_path.dart';
import 'package:rpmlauncher/widget/memory_slider.dart';

class _SettingScreenState extends State<SettingScreen> {
  Color get primaryColor => ThemeUtility.getTheme().colorScheme.primary;

  TextEditingController jvmArgsController = TextEditingController();
  TextEditingController gameWindowWidthController = TextEditingController();
  TextEditingController gameWindowHeightController = TextEditingController();
  TextEditingController wrapperCommandController = TextEditingController();
  TextEditingController gameLogMaxLineCountController = TextEditingController();

  late bool autoInstallJava;
  late bool checkAssetsIntegrity;
  late bool showGameLogs;
  late bool autoDownloadModDependencies;
  late bool autoFullScreen;
  late bool checkAccountValidity;
  late bool autoCloseGameLogsScreen;
  late bool discordRichPresence;

  String? backgroundPath;
  double javaMaxRam = launcherConfig.jvmMaxRam;

  VersionTypes updateChannel = launcherConfig.updateChannel;

  int selectedIndex = 0;

  @override
  void initState() {
    autoInstallJava = launcherConfig.autoInstallJava;
    checkAccountValidity = launcherConfig.checkAccountValidity;
    autoCloseGameLogsScreen = launcherConfig.autoCloseGameLogsScreen;
    checkAssetsIntegrity = launcherConfig.checkAssetsIntegrity;
    showGameLogs = launcherConfig.showGameLogs;
    autoDownloadModDependencies = launcherConfig.autoDownloadModDependencies;
    autoFullScreen = launcherConfig.autoFullScreen;
    discordRichPresence = launcherConfig.discordRichPresence;

    gameWindowWidthController.text = launcherConfig.gameWindowWidth.toString();
    gameWindowHeightController.text =
        launcherConfig.gameWindowHeight.toString();
    gameLogMaxLineCountController.text =
        launcherConfig.gameLogMaxLineCount.toString();
    wrapperCommandController.text = launcherConfig.wrapperCommand ?? "";
    jvmArgsController.text = JvmArgs.fromList(launcherConfig.jvmArgs).args;
    super.initState();
  }

  TextStyle title_ = const TextStyle(
    fontSize: 20.0,
    color: Colors.lightBlue,
  );

  @override
  void dispose() {
    jvmArgsController.dispose();
    gameWindowWidthController.dispose();
    gameWindowHeightController.dispose();
    wrapperCommandController.dispose();
    gameLogMaxLineCountController.dispose();
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
          optionWidgets: (StateSetter setViewState) {
            return [
              ListView(
                children: [
                  const JavaPathWidget(),
                  const Divider(),
                  SwitchListTile(
                    value: autoInstallJava,
                    onChanged: (value) {
                      setViewState(() {
                        autoInstallJava = !autoInstallJava;
                        launcherConfig.autoInstallJava = autoInstallJava;
                      });
                    },
                    title: Text(
                      I18n.format("settings.java.auto"),
                      style: title_,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(),
                  MemorySlider(
                      value: javaMaxRam,
                      onChanged: (memory) {
                        launcherConfig.jvmMaxRam = memory;
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
                        launcherConfig.jvmArgs = JvmArgs(args: value).toList();
                        setViewState(() {});
                      },
                    ),
                  ),
                ],
              ),
              ListView(
                children: [
                  Column(
                    children: [
                      LanguageSelectorWidget(
                        onChanged: () => setState(() {}),
                      ),
                      const Divider(),
                      Text(
                        I18n.format("settings.appearance.theme"),
                        style: title_,
                      ),
                      SelectorThemeWidget(
                        themeString: ThemeUtility.toI18nString(
                            ThemeUtility.getThemeEnumByConfig()),
                        setWidgetState: setViewState,
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
                                  launcherConfig.backgroundImageFile =
                                      File(file.path!);
                                  backgroundPath = file.path;
                                }
                                setViewState(() {});
                              },
                              child: Text(I18n.format(
                                  "settings.appearance.background.pick"))),
                          const SizedBox(width: 10),
                          ElevatedButton(
                              onPressed: () {
                                launcherConfig.backgroundImageFile = null;
                                backgroundPath = null;
                                setViewState(() {});
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
                              controller: gameWindowWidthController,
                              verify: (value) => int.tryParse(value) != null,
                              hintText: "854",
                              onChanged: (value) async {
                                launcherConfig.gameWindowWidth =
                                    int.tryParse(value) ?? 854;
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
                              controller: gameWindowHeightController,
                              hintText: "480",
                              verify: (value) => int.tryParse(value) != null,
                              onChanged: (value) async {
                                launcherConfig.gameWindowHeight =
                                    int.tryParse(value) ?? 480;
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
                        LauncherPath.currentDataHome.absolute.path,
                        style: const TextStyle(fontSize: 20)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                            onPressed: () async {
                              String? path =
                                  await FilePicker.platform.getDirectoryPath();

                              if (path != null) {
                                launcherConfig.launcherDataDir =
                                    Directory(path);
                                setViewState(() {});
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
                              launcherConfig.launcherDataDir =
                                  LauncherPath.defaultDataHome;
                              setViewState(() {});
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
                    value: checkAssetsIntegrity,
                    onChanged: (value) {
                      setViewState(() {
                        checkAssetsIntegrity = !checkAssetsIntegrity;
                        launcherConfig.checkAssetsIntegrity =
                            checkAssetsIntegrity;
                      });
                    },
                    title: I18nText("settings.advanced.assets.check",
                        style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: showGameLogs,
                    onChanged: (value) {
                      setViewState(() {
                        showGameLogs = value;
                        launcherConfig.showGameLogs = value;
                      });
                    },
                    title:
                        I18nText("settings.advanced.show_log", style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: autoDownloadModDependencies,
                    onChanged: (value) {
                      setViewState(() {
                        autoDownloadModDependencies = value;
                        launcherConfig.autoDownloadModDependencies = value;
                      });
                    },
                    title: I18nText("settings.advanced.auto_dependencies",
                        style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: autoFullScreen,
                    onChanged: (value) {
                      setViewState(() {
                        autoFullScreen = value;
                        launcherConfig.autoFullScreen = value;
                      });
                    },
                    title: I18nText("settings.advanced.auto_full_screen",
                        style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: checkAccountValidity,
                    onChanged: (value) {
                      setViewState(() {
                        checkAccountValidity = value;
                        launcherConfig.checkAccountValidity = value;
                      });
                    },
                    title: I18nText("settings.advanced.validate_account",
                        style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: autoCloseGameLogsScreen,
                    onChanged: (value) {
                      setViewState(() {
                        autoCloseGameLogsScreen = value;
                        launcherConfig.autoCloseGameLogsScreen = value;
                      });
                    },
                    title: I18nText("settings.advanced.auto_close_log_screen",
                        style: title_),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: discordRichPresence,
                    onChanged: (value) {
                      setViewState(() {
                        discordRichPresence = value;
                        launcherConfig.discordRichPresence = value;
                      });
                    },
                    title: I18nText("settings.advanced.discord_rpc",
                        style: title_),
                  ),
                  const Divider(),
                  ListTile(
                    title: I18nText("settings.advanced.update_channel",
                        style: title_),
                    trailing: StatefulBuilder(builder: (context, setState) {
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
                            setState(() {
                              updateChannel = channel;
                              launcherConfig.updateChannel = channel;
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
                        controller: gameLogMaxLineCountController,
                        verify: (value) => int.tryParse(value) != null,
                        hintText: "300",
                        onChanged: (value) async {
                          launcherConfig.gameLogMaxLineCount = int.parse(value);
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
                          launcherConfig.wrapperCommand =
                              value.isEmpty ? null : value;
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
                            Util.exit(0);
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
            Util.exit(0);
          },
        )
      ],
    );
  }
}

class SettingScreen extends StatefulWidget {
  static const String route = "/settings";

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}
