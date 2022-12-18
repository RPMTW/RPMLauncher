import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dart_discord_rpc/dart_discord_rpc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/database/database.dart';
import 'package:rpmlauncher/function/analytics.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/model/account/Account.dart';
import 'package:rpmlauncher/ui/screen/main_screen.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/theme/theme_provider.dart';
import 'package:rpmlauncher/ui/widget/dialog/CheckDialog.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';
import 'package:rpmtw_api_client/rpmtw_api_client.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:synchronized/extension.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final loadingStopwatch = Stopwatch();

  final List<String> tips = [
    'rpmlauncher.tips.1',
    'rpmlauncher.tips.2',
    'rpmlauncher.tips.3',
  ];
  late final String tip;

  @override
  void initState() {
    loadingStopwatch.start();
    loadingStopwatch.synchronized(() async {
      while (true) {
        if (!loadingStopwatch.isRunning) break;
        if (mounted) {
          setState(() {});
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    });
    tip = tips.elementAt(Random().nextInt(tips.length));

    super.initState();
    loading();
  }

  @override
  Widget build(BuildContext context) {
    double loadingProgress = loadingStopwatch.elapsedMilliseconds / 2800;

    if (loadingProgress > 1) {
      loadingProgress = 1;
    }

    if (loadingStopwatch.isRunning) {
      return ThemeProvider(builder: (context, theme) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LauncherTheme.getMaterialTheme(),
          home: Material(
            child: SafeArea(
              child: Container(
                color: context.theme.backgroundColor,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                I18nText('rpmlauncher.tips.title',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontStyle: FontStyle.italic,
                                        color: context.theme.subTextColor)),
                                const SizedBox(height: 5),
                                I18nText(tip,
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: context.theme.textColor),
                                    textAlign: TextAlign.left),
                              ]),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        alignment: Alignment.center,
                        child: FractionallySizedBox(
                          heightFactor: 0.6,
                          child: Lottie.asset(
                            'assets/images/loading_animation.json',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    } else {
      return const MainScreen();
    }
  }

  Future<void> loading() async {
    await Future.delayed(const Duration(milliseconds: 800 * 2));
    logger.info('Loading');
    await WindowHandler.init();
    await Data.argsInit();
    RPMTWApiClient.init();
    await Database.init();
    if (!kTestMode) {
      if (WindowHandler.isMainWindow) {
        try {
          DiscordRPC discordRPC = DiscordRPC(
              applicationId: 903883530822627370,
              libTempPath:
                  Directory(join(dataHome.path, 'discord-rpc-library')));
          await discordRPC.initialize();

          if (launcherConfig.discordRichPresence) {
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
        options.release = 'rpmlauncher@${LauncherInfo.getFullVersion()}';
        options.dsn =
            'https://18a8e66bd35c444abc0a8fa5b55843d7@o1068024.ingest.sentry.io/6062176';
        options.tracesSampleRate = 1.0;
        options.attachScreenshot = true;

        FutureOr<SentryEvent?> beforeSend(SentryEvent event,
            {dynamic hint}) async {
          if (launcherConfig.isInit && kReleaseMode) {
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
                      frames.package == 'rpmlauncher') {
                    githubSourceMap.add(
                        'https://github.com/RPMTW/RPMLauncher/blob/${LauncherInfo.isDebugMode ? 'develop' : LauncherInfo.getFullVersion()}/${frames.absPath?.replaceAll('package:rpmlauncher', 'lib/')}#L${frames.lineNo}');
                  }
                });
              });
            }
            newEvent = event.copyWith(
                user: SentryUser(
                    id: launcherConfig.googleAnalyticsClientId,
                    username: userName,
                    ipAddress: '{{auto}}',
                    data: {
                      'userOrigin': LauncherInfo.userOrigin,
                      'githubSourceMap': githubSourceMap,
                      'config': configHelper.getAll(),
                    }),
                contexts: event.contexts.copyWith(
                    device: SentryDevice(
                  arch: Util.getCPUArchitecture().replaceAll('AMD64', 'X86_64'),
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
                  screenResolution: '${size.width}x${size.height}',
                  theme: LauncherTheme.getTypeByConfig().name,
                  timezone: DateTime.now().timeZoneName,
                )),
                exceptions: exceptions);

            return newEvent;
          } else {
            return null;
          }
        }

        options.beforeSend = beforeSend;
      },
    );

    logger.info('OS Version: ${await RPMLauncherPlugin.platformVersion}');

    if (launcherConfig.autoFullScreen) {
      await WindowHandler.setFullScreen(true);
    }

    await googleAnalytics?.ping();
    // loadingStopwatch.stop();

    setState(() {});
  }
}
