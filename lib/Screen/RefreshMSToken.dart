import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/Account/MSAccountHandler.dart';
import 'package:rpmlauncher/Model/Account.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
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
  Account account = Account.getDefault();

  Widget loading = AlertDialog(
    title: Text(I18n.format('gui.tips.info')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [Text("正在嘗試自動更新您的帳號憑證"), SizedBox(height: 12), RWLLoading()],
    ),
  );

  Widget error = AlertDialog(
    title: Text(I18n.format('gui.error.info')),
    content: Text("自動更新登入憑證失敗，請手動重新登入"),
    actions: [
      TextButton(
          onPressed: () {
            navigator.pop();
            navigator.pop();
            showDialog(
                barrierDismissible: false,
                context: navigator.context,
                builder: (context) => MSLoginWidget());
          },
          child: Text("手動重新登入"))
    ],
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: account.credentials!.refresh(
          identifier: "b7df55b4-300f-4409-8ea9-a172f844aa15",
        ),
        builder: (context, AsyncSnapshot<Credentials> refreshSnapshot) {
          if (refreshSnapshot.hasData && !refreshSnapshot.hasError) {
            return FutureBuilder(
                future: MSAccountHandler.authorization(
                    refreshSnapshot.data!.accessToken),
                builder: (context, AsyncSnapshot<List> snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    Map _accountMap = snapshot.data![0];
                    String uuid = _accountMap["selectedProfile"]["id"];
                    String userName = _accountMap["selectedProfile"]["name"];

                    Account.add(AccountType.microsoft,
                        _accountMap['accessToken'], uuid, userName,
                        credentials: refreshSnapshot.data!);
                    return AlertDialog(
                      title: Text(I18n.format('gui.tips.info')),
                      content: Text("自動更新登入憑證成功"),
                      actions: [
                        OkClose(
                          onOk: () {
                            navigator.pop();
                          },
                        )
                      ],
                    );
                  } else if (snapshot.hasError) {
                    logger.error(ErrorType.network, snapshot.error.toString());
                    return error;
                  } else {
                    return loading;
                  }
                });
          } else if (refreshSnapshot.hasError) {
            logger.error(ErrorType.network, refreshSnapshot.error.toString());
            return error;
          } else {
            return loading;
          }
        });
  }
}
