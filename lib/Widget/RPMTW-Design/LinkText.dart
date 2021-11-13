import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/Utility.dart';

class LinkText extends StatelessWidget {
  String text;
  String link;

  LinkText({Key? key, required this.link, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(
      style: TextStyle(
        color: Colors.lightBlue,
      ),
      text: text,
      recognizer: TapGestureRecognizer()..onTap = () => Uttily.openUri(link),
    ));
  }
}
