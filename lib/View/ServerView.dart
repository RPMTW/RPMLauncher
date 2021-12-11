import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/Background.dart';

class ServerView extends StatelessWidget {
  const ServerView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Background(child: Text("伺服器"));
  }
}
