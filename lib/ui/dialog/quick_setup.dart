import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/i18n/language_selector.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/link_text.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/on_close.dart';

class QuickSetup extends StatefulWidget {
  const QuickSetup({
    Key? key,
  }) : super(key: key);

  @override
  State<QuickSetup> createState() => _QuickSetupState();
}

class _QuickSetupState extends State<QuickSetup> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(I18n.format('init.quick_setup.title'),
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${I18n.format('init.quick_setup.content')}\n"),
            LanguageSelectorWidget(
              onChanged: () => setState(() {}),
            ),
          ],
        ),
        actions: [
          OkClose(
            title: I18n.format('gui.next'),
            onOk: () {
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                          scrollable: true,
                          title: I18nText("rpmlauncher.privacy.title",
                              textAlign: TextAlign.center),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              I18nText("rpmlauncher.privacy.content.1"),
                              const SizedBox(
                                height: 10,
                              ),
                              I18nText("rpmlauncher.privacy.content.2"),
                              const SizedBox(
                                height: 10,
                              ),
                              I18nText("rpmlauncher.privacy.content.3"),
                              const SizedBox(
                                height: 10,
                              ),
                              LinkText(
                                  link: "https://policies.google.com/privacy",
                                  text: I18n.format(
                                      'rpmlauncher.privacy.google')),
                              LinkText(
                                  link: "https://sentry.io/privacy/",
                                  text:
                                      I18n.format('rpmlauncher.privacy.sentry'))
                            ],
                          ),
                          actions: [
                            OkClose(
                              title: I18n.format('gui.disagree'),
                              color: Colors.white24,
                              onOk: () {
                                Util.exit(0);
                              },
                            ),
                            OkClose(
                              title: I18n.format('gui.agree'),
                              onOk: () {
                                launcherConfig.isInit = true;
                                googleAnalytics?.firstVisit();
                              },
                            ),
                          ]));
            },
          ),
        ]);
  }
}
