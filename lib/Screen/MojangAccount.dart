import 'package:flutter/material.dart';
import 'package:rpmlauncher/Account/MojangAccountHandler.dart';
import 'package:rpmlauncher/Model/Account/Account.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

class _MojangAccountState extends State<MojangAccount> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwdController = TextEditingController();

  bool _obscureText = true;

  _MojangAccountState();

  @override
  void initState() {
    emailController.text = widget.accountEmail;

    super.initState();
    setState(() {});
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  var title_ = const TextStyle(
    fontSize: 20.0,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AlertDialog(
        title: I18nText("account.add.mojang.title"),
        scrollable: true,
        content: Column(
          children: [
            TextField(
              key: const Key('mojang_email'),
              decoration: InputDecoration(
                  labelText: I18n.format('account.mojang.title'),
                  hintText: I18n.format('account.mojang.title.hint'),
                  prefixIcon: const Icon(Icons.person)),
              controller: emailController, // 設定控制器
            ),
            TextField(
              key: const Key('mojang_passwd'),
              decoration: InputDecoration(
                  labelText: I18n.format('account.mojang.passwd'),
                  hintText: I18n.format('account.mojang.passwd.hint'),
                  prefixIcon: const Icon(Icons.password)),
              controller: passwdController,
              obscureText: _obscureText, // 設定控制器
            ),
            TextButton(
                onPressed: _toggle,
                child: Text(_obscureText
                    ? I18n.format('account.passwd.show')
                    : I18n.format('account.passwd.hide'))),
            const SizedBox(height: 10),
            TextButton.icon(
              label: Text(I18n.format("gui.login")),
              icon: const Icon(
                Icons.login,
                size: 20,
              ),
              onPressed: () async {
                if (emailController.text == "" || passwdController.text == "") {
                  await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: I18nText.errorInfoText(),
                          content: I18nText("account.error.empty"),
                          actions: [
                            TextButton(
                              child: Text(I18n.format("gui.confirm")),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      });
                } else {
                  await showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: I18nText.tipsInfoText(),
                          content: FutureBuilder(
                              future: MojangHandler.logIn(
                                emailController.text,
                                passwdController.text,
                              ),
                              builder: (BuildContext context,
                                  AsyncSnapshot snapshot) {
                                if (snapshot.hasError ||
                                    snapshot.data.runtimeType == String) {
                                  if (snapshot.data ==
                                      "ForbiddenOperationException") {
                                    return I18nText(
                                        "account.error.forbidden_operation_exception");
                                  } else {
                                    return Column(
                                      children: [
                                        I18nText("gui.error.unknown"),
                                        Text(snapshot.error.toString()),
                                      ],
                                    );
                                  }
                                } else if (snapshot.hasData) {
                                  Map data = snapshot.data;
                                  String uuid;

                                  try {
                                    uuid = data["selectedProfile"]["id"];
                                  } catch (e) {
                                    uuid = data["availableProfiles"][0]["id"];
                                  }

                                  String userName =
                                      data["selectedProfile"]["name"];
                                  String token = data["accessToken"];

                                  AccountStorage().add(
                                      AccountType.mojang, token, uuid, userName,
                                      email: data["user"]["username"]);

                                  return I18nText("account.add.successful");
                                } else {
                                  return SizedBox(
                                    child: Center(
                                      child: Column(
                                        children: [
                                          const RWLLoading(),
                                          const SizedBox(height: 10),
                                          I18nText("account.add.loading")
                                        ],
                                      ),
                                    ),
                                    height: 80,
                                    width: 100,
                                  );
                                }
                              }),
                          actions: [
                            TextButton(
                              child: Text(I18n.format("gui.confirm")),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                if (widget.accountEmail != "") {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        );
                      });
                }
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_sharp),
            tooltip: I18n.format("gui.close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class MojangAccount extends StatefulWidget {
  final String accountEmail;

  const MojangAccount({this.accountEmail = ''});

  @override
  _MojangAccountState createState() => _MojangAccountState();
}
