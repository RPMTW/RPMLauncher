import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:provider/provider.dart';
import 'package:rpmlauncher/function/counter.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/util/data.dart';

import 'package:rpmlauncher/route/GenerateRoute.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/theme.dart';
import 'package:rpmlauncher/route/RPMNavigatorObserver.dart';
import 'package:rpmlauncher/util/updater.dart';
import 'package:rpmlauncher/widget/dialog/quick_setup.dart';
import 'package:rpmlauncher/widget/dialog/UpdaterDialog.dart';
import 'package:rpmlauncher/widget/launcher_shortcuts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen();
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // TODO: support test mode
      if (!mounted || kTestMode) return;

      if (!launcherConfig.isInit) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const QuickSetup());
      } else if (WindowHandler.isMainWindow) {
        Updater.checkForUpdate(Updater.fromConfig()).then((VersionInfo info) {
          if (info.needUpdate && mounted) {
            showDialog(
                context: context,
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
        return Counter.create();
      },
      child: DynamicThemeBuilder(builder: (context, theme) {
        return LauncherShortcuts(
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: NavigationService.navigationKey,
              title: LauncherInfo.getUpperCaseName(),
              theme: theme,
              navigatorObservers: [
                RPMNavigatorObserver(),
                SentryNavigatorObserver()
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
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
                        Text(title, style: style, textAlign: TextAlign.center),
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

                return widget ??
                    Scaffold(body: Center(child: Text(title, style: style)));
              },
              onGenerateInitialRoutes: (String initialRouteName) {
                return [
                  onGenerateRoute(RouteSettings(name: LauncherInfo.route))
                ];
              },
              onGenerateRoute: (RouteSettings settings) =>
                  onGenerateRoute(settings)),
        );
      }),
    );
  }
}
