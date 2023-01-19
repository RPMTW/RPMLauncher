import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';

class RPMLToolBar extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final Widget icon;
  final List<Widget> actions;
  const RPMLToolBar(
      {super.key,
      this.label,
      this.onPressed,
      this.icon = const Icon(Icons.undo_rounded),
      this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 65),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: context.theme.mainColor.withOpacity(0.3),
              blurRadius: 50,
              blurStyle: BlurStyle.outer,
            )
          ],
          borderRadius: BorderRadius.circular(13),
          border: Border.all(width: 2, color: context.theme.primaryColor)),
      child: Blur(
          blur: 15,
          blurColor: context.theme.mainColor,
          colorOpacity: 0.3,
          borderRadius: BorderRadius.circular(10),
          overlay: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(width: 10),
                  Wrap(
                    spacing: 12,
                    children: actions,
                  )
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    height: 65,
                    child: ElevatedButton.icon(
                        label: Text(label ?? '返回首頁',
                            style: TextStyle(
                                color: context.theme.textColor, fontSize: 18)),
                        icon: IconTheme(
                          data: IconThemeData(
                              color: context.theme.textColor, size: 30),
                          child: icon,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.theme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (onPressed != null) {
                            onPressed!();
                          } else {
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          }
                        }),
                  ),
                ],
              )
            ],
          ),
          child: Container()),
    );
  }
}
