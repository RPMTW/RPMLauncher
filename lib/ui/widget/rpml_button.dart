import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';

class RPMLButton extends StatelessWidget {
  final String label;
  final Widget? icon;
  final Function()? onPressed;

  final double? width;
  final double height;
  final Color? color;
  final TextStyle? labelStyle;
  final bool isOutline;

  const RPMLButton(
      {Key? key,
      required this.label,
      this.icon,
      this.onPressed,
      this.height = 45,
      this.width,
      this.color,
      this.labelStyle,
      this.isOutline = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconSize = height - 20;
    final buttonColor = color ?? context.theme.primaryColor;
    final textColor = isOutline ? buttonColor : context.theme.textColor;

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
          onPressed: () {
            onPressed?.call();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: isOutline ? null : buttonColor,
            side: isOutline
                ? BorderSide(color: buttonColor, width: 2)
                : BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.all(10),
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
                              color: textColor,
                            ),
                            child: icon!)),
                    const SizedBox(width: 9),
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
                  style: labelStyle ?? TextStyle(color: textColor),
                ),
              ),
            ),
          ])),
    );
  }
}
