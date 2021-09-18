import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/main.dart';

import 'MSOauth2Login.dart';

class RefreshMsTokenScreen extends StatefulWidget {
  const RefreshMsTokenScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<RefreshMsTokenScreen> createState() => _RefreshMsTokenScreenState();
}

class _RefreshMsTokenScreenState extends State<RefreshMsTokenScreen> {
  Map Account = account.getByIndex(account.getIndex());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Credentials.fromJson(Account['Credentials']).refresh(
            identifier: "b7df55b4-300f-4409-8ea9-a172f844aa15",
            secret: '9d66614a-7713-4cfa-92e0-c0517f9bc769'),
        builder: (context, AsyncSnapshot<Credentials> snapshot) {
          if (snapshot.hasData && !snapshot.hasError) {
            account.Add(
                account.Microsoft,
                snapshot.data!.accessToken,
                Account['UUID'],
                Account['UserName'],
                null,
                snapshot.data!.toJson());
            return AlertDialog(
              title: Text(i18n.format('gui.tips.info')),
              content: Text("自動更新登入憑證成功"),
              actions: [OkClose()],
            );
          } else if (snapshot.hasError) {
            logger.send(snapshot.error);
            return AlertDialog(
              title: Text(i18n.format('gui.error.info')),
              content: Text("自動更新登入憑證失敗，請手動重新登入"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) => MSLoginWidget());
                    },
                    child: Text("手動重新登入"))
              ],
            );
          } else {
            return AlertDialog(
              title: Text(i18n.format('gui.tips.info')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("正在嘗試自動更新您的帳號憑證"),
                  SizedBox(height: 12),
                  CircularProgressIndicator()
                ],
              ),
            );
          }
        });
  }
}
