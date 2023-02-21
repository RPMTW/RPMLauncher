import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:no_context_navigation/no_context_navigation.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/route/rpml_navigator_observer.dart';
import 'package:rpmlauncher/route/generate_route.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/theme/theme_provider.dart';
import 'package:rpmlauncher/ui/widget/launcher_shortcuts.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      builder: (context, theme) {
        return LauncherShortcuts(
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: NavigationService.navigationKey,
              title: LauncherInfo.getUpperCaseName(),
              theme: LauncherTheme.getMaterialTheme(context),
              navigatorObservers: [
                RPMLNavigatorObserver(),
                // SentryNavigatorObserver()
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
                          '\n${I18n.format('rpmlauncher.crash.antivirus_software')}';
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
                              'gui.error.message',
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
                              'rpmlauncher.crash.stacktrace',
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
              initialRoute: LauncherInfo.route,
              onGenerateRoute: onGenerateRoute),
        );
      },
    );
  }
}
