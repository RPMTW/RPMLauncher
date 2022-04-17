import 'dart:io';

import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:provider/provider.dart';
import 'package:rpmlauncher/function/counter.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/util/Config.dart';
import 'package:rpmlauncher/util/Data.dart';

import 'package:rpmlauncher/route/GenerateRoute.dart';
import 'package:rpmlauncher/screen/HomePage.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/Intents.dart';
import 'package:rpmlauncher/util/LauncherInfo.dart';
import 'package:rpmlauncher/util/RPMFeedbackLocalizations.dart';
import 'package:rpmlauncher/util/theme.dart';
import 'package:rpmlauncher/route/RPMNavigatorObserver.dart';
import 'package:rpmlauncher/util/updater.dart';
import 'package:rpmlauncher/widget/dialog/QuickSetup.dart';
import 'package:rpmlauncher/widget/dialog/UpdaterDialog.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_manager/window_manager.dart';

class LauncherHome extends StatefulWidget {
  const LauncherHome();
  @override
  State<LauncherHome> createState() => _LauncherHomeState();
}

class _LauncherHomeState extends State<LauncherHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;

      if (Config.getValue('init') == false) {
        showDialog(
            context: navigator.context,
            barrierDismissible: false,
            builder: (context) => const QuickSetup());
      } else if (WindowHandler.isMainWindow) {
        Updater.checkForUpdate(Updater.fromConfig()).then((VersionInfo info) {
          if (info.needUpdate && mounted) {
            showDialog(
                context: navigator.context,
                builder: (context) => UpdaterDialog(info: info));
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) {
        logger.info("Provider Created");
        return Counter();
      },
      child: DynamicTheme(
          themeCollection: ThemeUtility.themeCollection(context),
          defaultThemeId: ThemeUtility.toInt(Themes.dark),
          builder: (context, theme) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                navigatorKey: NavigationService.navigationKey,
                title: LauncherInfo.getUpperCaseName(),
                theme: theme,
                navigatorObservers: [
                  RPMNavigatorObserver(),
                  SentryNavigatorObserver()
                ],
                shortcuts: <LogicalKeySet, Intent>{
                  LogicalKeySet(LogicalKeyboardKey.escape): EscIntent(),
                  LogicalKeySet(
                          LogicalKeyboardKey.control, LogicalKeyboardKey.keyR):
                      RestartIntent(),
                  LogicalKeySet(
                          LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
                      FeedBackIntent(),
                  LogicalKeySet(
                    LogicalKeyboardKey.f11,
                  ): FullScreenIntent(),
                },
                actions: <Type, Action<Intent>>{
                  EscIntent:
                      CallbackAction<EscIntent>(onInvoke: (EscIntent intent) {
                    if (navigator.canPop()) {
                      try {
                        navigator.pop(true);
                      } catch (e) {
                        navigator.pop();
                      }
                    }
                    return;
                  }),
                  RestartIntent: CallbackAction<RestartIntent>(
                      onInvoke: (RestartIntent intent) {
                    logger.info("Reload");
                    navigator.pushReplacementNamed(HomePage.route);
                    Future.delayed(Duration.zero, () {
                      showDialog(
                          context: navigator.context,
                          builder: (context) => AlertDialog(
                                title: Text(I18n.format('uttily.reload')),
                                actions: const [OkClose()],
                              ));
                    });
                    return;
                  }),
                  FeedBackIntent: CallbackAction<FeedBackIntent>(
                      onInvoke: (FeedBackIntent intent) {
                    LauncherInfo.feedback(context);
                    return;
                  }),
                  FullScreenIntent: CallbackAction<FullScreenIntent>(
                      onInvoke: (FullScreenIntent intent) async {
                    if (WindowHandler.isMainWindow || kReleaseMode) {
                      bool isFullScreen = await windowManager.isFullScreen();
                      await windowManager.setFullScreen(!isFullScreen);
                    }

                    return;
                  }),
                },
                builder: (BuildContext context, Widget? widget) {
                  String title = I18n.format('rpmlauncher.crash');
                  TextStyle style = const TextStyle(fontSize: 30);
                  if (!kTestMode) {
                    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                      Object exception = errorDetails.exception;

                      if (exception is FileSystemException) {
                        title +=
                            "\n${I18n.format('rpmlauncher.crash.antivirus_software')}";
                      }

                      return Material(
                          child: Column(
                        children: [
                          Text(title,
                              style: style, textAlign: TextAlign.center),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              I18nText(
                                "gui.error.message",
                                style: style,
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_outlined),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: errorDetails.exceptionAsString()));
                                },
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(errorDetails.exceptionAsString()),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              I18nText(
                                "rpmlauncher.crash.stacktrace",
                                style: style,
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_outlined),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: errorDetails.stack.toString()));
                                },
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              children: errorDetails.stack
                                  .toString()
                                  .split('\n')
                                  .map((e) => Text(e))
                                  .toList(),
                            ),
                          ),
                        ],
                      ));
                    };
                  }

                  return BetterFeedback(
                    theme: FeedbackThemeData(
                      background: Colors.white10,
                      feedbackSheetColor: Colors.white12,
                      bottomSheetDescriptionStyle: const TextStyle(
                        fontFamily: 'font',
                        color: Colors.white,
                      ),
                    ),
                    localeOverride: WidgetsBinding.instance.window.locale,
                    localizationsDelegates: const [
                      RPMFeedbackLocalizationsDelegate(),
                    ],
                    child: widget ??
                        Scaffold(
                            body: Center(child: Text(title, style: style))),
                  );
                },
                onGenerateInitialRoutes: (String initialRouteName) {
                  return [
                    onGenerateRoute(RouteSettings(name: LauncherInfo.route))
                  ];
                },
                onGenerateRoute: (RouteSettings settings) =>
                    onGenerateRoute(settings));
          }),
    );
  }
}
