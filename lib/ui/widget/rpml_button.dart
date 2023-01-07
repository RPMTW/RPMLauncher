import 'package:blur/blur.dart';
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
  final RPMLButtonLabelType labelType;
  final bool isOutline;
  final double? backgroundBlur;

  const RPMLButton(
      {Key? key,
      required this.label,
      this.icon,
      this.onPressed,
      this.height = 45,
      this.width = 45,
      this.color,
      this.labelStyle,
      this.labelType = RPMLButtonLabelType.tooltip,
      this.isOutline = false,
      this.backgroundBlur})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconSize = height / 2;
    final buttonColor = color ?? context.theme.primaryColor;
    final textColor = context.theme.textColor;

    final content = Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null)
        Row(
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
            if (labelType == RPMLButtonLabelType.text) const SizedBox(width: 9),
          ],
        ),
      if (labelType == RPMLButtonLabelType.text)
        SizedBox(
          height: height / 2,
          child: FittedBox(
            child: Text(
              label,
              style: labelStyle ?? TextStyle(color: textColor),
            ),
          ),
        ),
    ]);

    final button = OutlinedButton(
        onPressed: () {
          onPressed?.call();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isOutline ? null : buttonColor,
          side: isOutline
              ? BorderSide(color: context.theme.borderColor, width: 2)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(0),
        ),
        child: backgroundBlur != null
            ? Blur(
                blur: backgroundBlur!,
                overlay: content,
                colorOpacity: 0.2,
                blurColor: Colors.black,
                child: Container(),
              )
            : content);

    return SizedBox(
      width: width,
      height: height,
      child: labelType == RPMLButtonLabelType.tooltip
          ? Tooltip(
              message: label,
              child: button,
            )
          : button,
    );
  }
}

enum RPMLButtonLabelType { text, tooltip }
