import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/Account/MSAccountHandler.dart';
import 'package:rpmlauncher/Model/Account/Account.dart';
import 'package:rpmlauncher/Utility/Logger.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/Utility/Data.dart';

import 'MSOauth2Login.dart';

class RefreshMsTokenScreen extends StatefulWidget {
  const RefreshMsTokenScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<RefreshMsTokenScreen> createState() => _RefreshMsTokenScreenState();
}

class _RefreshMsTokenScreenState extends State<RefreshMsTokenScreen> {
  Account account = AccountStorage().getDefault()!;

  Widget loading = AlertDialog(
    title: Text(I18n.format('gui.tips.info')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        I18nText("account.refresh.microsoft.auto"),
        SizedBox(height: 12),
        RWLLoading()
      ],
    ),
  );

  Widget error = AlertDialog(
    title: Text(I18n.format('gui.error.info')),
    content: I18nText("account.refresh.microsoft.error"),
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
          child: I18nText("account.refresh.microsoft.error.action"))
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
            return StreamBuilder<MicrosoftAccountStatus>(
                stream: MSAccountHandler.authorization(refreshSnapshot.data!),
                initialData: MicrosoftAccountStatus.xbl,
                builder: (context, snapshot) {
                  MicrosoftAccountStatus status = snapshot.data!;
                  status.refresh = true;

                  if (status == MicrosoftAccountStatus.successful) {
                    status.getAccountData()!.save();
                  }

                  if (status.isError) {
                    return AlertDialog(
                      title: I18nText.errorInfoText(),
                      content: Text(status.stateName),
                      actions: [
                        OkClose(
                          onOk: () {
                            navigator.pop();
                          },
                        )
                      ],
                    );
                  } else {
                    return AlertDialog(
                      title: I18nText("account.add.microsoft.state.title"),
                      content: Text(status.stateName),
                      actions: status == MicrosoftAccountStatus.successful
                          ? [
                              OkClose(
                                onOk: () {
                                  navigator.pop();
                                },
                              )
                            ]
                          : null,
                    );
                  }
                });
          } else if (refreshSnapshot.hasError) {
            logger.error(ErrorType.network, refreshSnapshot.error,
                stackTrace: refreshSnapshot.stackTrace);
            return error;
          } else {
            return loading;
          }
        });
  }
}
