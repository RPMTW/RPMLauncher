import 'dart:async';
import 'dart:io';

import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/function/analytics.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/screen/main_screen.dart';
import 'package:rpmlauncher/util/Config.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/LauncherInfo.dart';
import 'package:rpmlauncher/util/Logger.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/theme.dart';
import 'package:rpmlauncher/widget/RWLLoading.dart';
import 'package:rpmlauncher/widget/dialog/CheckDialog.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:system_info/system_info.dart';

import 'package:rpmlauncher/model/account/Account.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  Future<void> loading() async {
    logger.info("Loading");
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!kTestMode) {
      await WindowHandler.init();

      if (WindowHandler.isMainWindow) {
        try {
          DiscordRPC discordRPC = DiscordRPC(
              applicationId: 903883530822627370,
              libTempPath:
                  Directory(join(dataHome.path, 'discord-rpc-library')));
          await discordRPC.initialize();

          if (Config.getValue('discord_rpc')) {
            discordRPC.handler.start(autoRegister: true);
            discordRPC.handler.updatePresence(
              DiscordPresence(
                  state: 'https://www.rpmtw.com/RWL',
                  details: I18n.format('rpmlauncher.discord_rpc.details'),
                  startTimeStamp: LauncherInfo.startTime.millisecondsSinceEpoch,
                  largeImageKey: 'rwl_logo',
                  largeImageText:
                      I18n.format('rpmlauncher.discord_rpc.largeImageText'),
                  smallImageKey: 'minecraft',
                  smallImageText:
                      '${LauncherInfo.getFullVersion()} - ${LauncherInfo.getVersionType().name}'),
            );
          }
        } catch (e) {
          logger.error(ErrorType.io, 'failed to initialize discord rpc\n$e');
        }
      }

      googleAnalytics = Analytics();

      FlutterWindowClose.setWindowShouldCloseHandler(() async {
        if (WindowHandler.isMainWindow) {
          return await showDialog(
              context: navigator.context,
              builder: (context) {
                return CheckDialog(
                  title: I18n.format('rpmlauncher.exit_confirm.title'),
                  onPressedOK: (context) {
                    WindowHandler.close()
                        .then((value) => Navigator.of(context).pop(true));
                  },
                  onPressedCancel: (context) {
                    Navigator.of(context).pop(false);
                  },
                );
              });
        } else {
          await WindowHandler.close();
          return true;
        }
      });
    }

    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      FlutterError.presentError(errorDetails);
      logger.error(ErrorType.flutter, errorDetails.exceptionAsString(),
          stackTrace: errorDetails.stack ?? StackTrace.current);
    };

    await SentryFlutter.init(
      (options) {
        options.release = "rpmlauncher@${LauncherInfo.getFullVersion()}";
        options.dsn =
            'https://18a8e66bd35c444abc0a8fa5b55843d7@o1068024.ingest.sentry.io/6062176';
        options.tracesSampleRate = 1.0;
        FutureOr<SentryEvent?> beforeSend(SentryEvent event,
            {dynamic hint}) async {
          if (Config.getValue('init') == true && kReleaseMode) {
            MediaQueryData data =
                MediaQueryData.fromWindow(WidgetsBinding.instance.window);
            Size size = data.size;
            String? userName = AccountStorage().getDefault()?.username ??
                Platform.environment['USERNAME'];

            SentryEvent newEvent;

            List<String> githubSourceMap = [];

            List<SentryException>? exceptions = event.exceptions;
            if (exceptions != null) {
              exceptions.forEach((SentryException exception) {
                exception.stackTrace?.frames.forEach((frames) {
                  if ((frames.inApp ?? false) &&
                      frames.package == "rpmlauncher") {
                    githubSourceMap.add(
                        "https://github.com/RPMTW/RPMLauncher/blob/${LauncherInfo.isDebugMode ? "develop" : LauncherInfo.getFullVersion()}/${frames.absPath?.replaceAll("package:rpmlauncher", "lib/")}#L${frames.lineNo}");
                  }
                });
              });
            }
            newEvent = event.copyWith(
                user: SentryUser(
                    id: Config.getValue('ga_client_id'),
                    username: userName,
                    extras: {
                      "userOrigin": LauncherInfo.userOrigin,
                      "githubSourceMap": githubSourceMap,
                      "config": Config.toMap()
                    }),
                contexts: event.contexts.copyWith(
                    device: SentryDevice(
                  arch:
                      SysInfo.kernelArchitecture.replaceAll("AMD64", "X86_64"),
                  memorySize:
                      ((await RPMLauncherPlugin.getTotalPhysicalMemory())
                                  .physical *
                              1024 *
                              1024)
                          .toInt(),
                  language: Platform.localeName,
                  name: Platform.localHostname,
                  simulator: false,
                  screenHeightPixels: size.height.toInt(),
                  screenWidthPixels: size.width.toInt(),
                  screenDensity: data.devicePixelRatio,
                  online: true,
                  screenDpi: (data.devicePixelRatio * 160).toInt(),
                  screenResolution: "${size.width}x${size.height}",
                  theme:
                      ThemeUtility.getThemeEnumByID(Config.getValue('theme_id'))
                          .name,
                  timezone: DateTime.now().timeZoneName,
                )),
                exceptions: exceptions);

            return newEvent;
          } else {
            return null;
          }
        }

        options.beforeSend = beforeSend;
        if (LauncherInfo.isDebugMode) {
          options.reportSilentFlutterErrors = true;
        }
      },
    );

    logger.info("OS Version: ${await RPMLauncherPlugin.platformVersion}");

    if (LauncherInfo.autoFullScreen) {
      await WindowHandler.setFullScreen(true);
    }

    await googleAnalytics?.ping();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: loading(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const MainScreen();
          } else {
            return DynamicThemeBuilder(
                builder: (context, theme) => MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: theme,
                      home: const Material(
                          child: RWLLoading(animations: true, logo: true)),
                    ));
          }
        });
  }
}
