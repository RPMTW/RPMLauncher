import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpmlauncher/handler/window_handler.dart';
import 'package:rpmlauncher/screen/home_page.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/Intents.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';

class LauncherShortcuts extends StatelessWidget {
  final Widget child;

  const LauncherShortcuts({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        EscIntent: CallbackAction<EscIntent>(onInvoke: (EscIntent intent) {
          if (navigator.canPop()) {
            try {
              navigator.pop(true);
            } catch (e) {
              navigator.pop();
            }
          }
          return;
        }),
        RestartIntent:
            CallbackAction<RestartIntent>(onInvoke: (RestartIntent intent) {
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
        FullScreenIntent: CallbackAction<FullScreenIntent>(
            onInvoke: (FullScreenIntent intent) async {
          bool isFullScreen = await WindowHandler.isFullScreen();
          await WindowHandler.setFullScreen(!isFullScreen);
          return;
        }),
      },
      child: Shortcuts(shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): EscIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR):
            RestartIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.f11,
        ): FullScreenIntent(),
      }, child: child),
    );
  }
}
