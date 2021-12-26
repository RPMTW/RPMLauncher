import 'dart:io';

import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:feedback_sentry/feedback_sentry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:provider/provider.dart';
import 'package:rpmlauncher/Function/Counter.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/Data.dart';

import 'package:rpmlauncher/Route/GenerateRoute.dart';
import 'package:rpmlauncher/Route/RPMRouteSettings.dart';
import 'package:rpmlauncher/Screen/HomePage.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Intents.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/RPMFeedbackLocalizations.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:rpmlauncher/Route/RPMNavigatorObserver.dart';
import 'package:rpmlauncher/Utility/Updater.dart';
import 'package:rpmlauncher/Widget/Dialog/QuickSetup.dart';
import 'package:rpmlauncher/Widget/Dialog/UpdaterDialog.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class LauncherHome extends StatefulWidget {
  @override
  State<LauncherHome> createState() => _LauncherHomeState();
}

class _LauncherHomeState extends State<LauncherHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      if (Config.getValue('init') == false && mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => QuickSetup());
      } else {
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
        logger.info("Provider Create");
        return Counter();
      },
      child: BetterFeedback(
        theme: FeedbackThemeData(
          background: Colors.white10,
          feedbackSheetColor: Colors.white12,
          bottomSheetDescriptionStyle: TextStyle(
            fontFamily: 'font',
            color: Colors.white,
          ),
        ),
        localizationsDelegates: [
          RPMFeedbackLocalizationsDelegate(),
        ],
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
                    LogicalKeySet(LogicalKeyboardKey.control,
                        LogicalKeyboardKey.keyR): RestartIntent(),
                    LogicalKeySet(LogicalKeyboardKey.control,
                        LogicalKeyboardKey.keyF): FeedBackIntent(),
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
                    }),
                    RestartIntent: CallbackAction<RestartIntent>(
                        onInvoke: (RestartIntent intent) {
                      logger.send("Reload");
                      navigator.pushReplacementNamed(HomePage.route);
                      Future.delayed(Duration.zero, () {
                        showDialog(
                            context: navigator.context,
                            builder: (context) => AlertDialog(
                                  title: Text(I18n.format('uttily.reload')),
                                  actions: [OkClose()],
                                ));
                      });
                    }),
                    FeedBackIntent: CallbackAction<FeedBackIntent>(
                        onInvoke: (FeedBackIntent intent) {
                      LauncherInfo.feedback(context);
                    }),
                  },
                  builder: (BuildContext context, Widget? widget) {
                    String _ = I18n.format('rpmlauncher.crash');
                    TextStyle _style = TextStyle(fontSize: 30);
                    if (!kTestMode) {
                      ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                        Object exception = errorDetails.exception;

                        if (exception is FileSystemException) {
                          _ +=
                              "\n${I18n.format('rpmlauncher.crash.antivirus_software')}";
                        }

                        return Material(
                            child: Column(
                          children: [
                            Text(_, style: _style, textAlign: TextAlign.center),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                I18nText(
                                  "gui.error.message",
                                  style: _style,
                                ),
                                IconButton(
                                  icon: Icon(Icons.copy_outlined),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text:
                                            errorDetails.exceptionAsString()));
                                  },
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(errorDetails.exceptionAsString()),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                I18nText(
                                  "rpmlauncher.crash.stacktrace",
                                  style: _style,
                                ),
                                IconButton(
                                  icon: Icon(Icons.copy_outlined),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: errorDetails.stack.toString()));
                                  },
                                ),
                              ],
                            ),
                            SizedBox(
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

                    return widget ??
                        Scaffold(body: Center(child: Text(_, style: _style)));
                  },
                  onGenerateInitialRoutes: (String initialRouteName) {
                    return [
                      navigator.widget.onGenerateRoute!(RPMRouteSettings(
                          name: LauncherInfo.route,
                          newWindow: LauncherInfo.newWindow)) as Route,
                    ];
                  },
                  onGenerateRoute: (RouteSettings settings) =>
                      onGenerateRoute(settings));
            }),
      ),
    );
  }
}
