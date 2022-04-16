import 'dart:async';
import 'dart:io';

import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Screen/LauncherHome.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:system_info/system_info.dart';
import 'package:rpmlauncher/Model/Account/Account.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

import 'Utility/Config.dart';
import 'Utility/Data.dart';
import 'Utility/I18n.dart';
import 'Utility/LauncherInfo.dart';
import 'Utility/Logger.dart';
import 'Utility/Theme.dart';
import 'Utility/Utility.dart';

Future<void> main(List<String> args) async {
  launcherArgs = args;

  await run();
}

Future<void> run() async {
  await runZonedGuarded(() async {
    LauncherInfo.startTime = DateTime.now();
    LauncherInfo.isDebugMode = kDebugMode;
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
    if (!kTestMode) {
      setWindowMinSize(const Size(960.0, 640.0));
      setWindowMaxSize(Size.infinite);
    }
    await Data.init();
    logger.info("Starting");

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
                  memorySize: await RPMLauncherPlugin.getTotalPhysicalMemory() *
                      1024 *
                      1024,
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

    runApp(const LauncherHome());

    logger.info("OS Version: ${await RPMLauncherPlugin.platformVersion}");

    if (LauncherInfo.autoFullScreen) {
      await windowManager.setFullScreen(true);
    }

    await googleAnalytics.ping();

    if (Config.getValue('discord_rpc')) {
      try {
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
      } catch (e) {}
    }

    logger.info("Start Done");
  }, (exception, stackTrace) async {
    if (Uttily.exceptionFilter(exception, stackTrace)) return;

    logger.error(ErrorType.unknown, exception, stackTrace: stackTrace);
    if (!LauncherInfo.isDebugMode && !kTestMode) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
    }
  });
}
