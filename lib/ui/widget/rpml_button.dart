import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';

class RPMLButton extends StatelessWidget {
  final String label;
  final Widget? icon;
  final Function()? onPressed;
  final double? width;
  final double height;
  final TextStyle? labelStyle;

  const RPMLButton(
      {Key? key,
      required this.label,
      this.icon,
      this.onPressed,
      this.height = 50,
      this.width,
      this.labelStyle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double iconSize = height - 24;

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
          onPressed: () {
            onPressed?.call();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: context.theme.mainColor.withOpacity(0.30),
            foregroundColor: const Color(0xFF3C7755),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: Row(children: [
            Builder(builder: (context) {
              if (icon != null) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                        height: iconSize,
                        child: IconTheme.merge(
                            data: IconThemeData(
                              size: iconSize,
                            ),
                            child: icon!)),
                    const SizedBox(width: 15),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
            SizedBox(
              height: height / 2,
              child: FittedBox(
                child: Text(
                  label,
                  style:
                      labelStyle ?? TextStyle(color: context.theme.textColor),
                ),
              ),
            ),
          ])),
    );
  }
}
