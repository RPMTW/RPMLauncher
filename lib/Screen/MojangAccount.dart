import 'package:flutter/material.dart';
import 'package:rpmlauncher/Account/MojangAccountHandler.dart';
import 'package:rpmlauncher/Model/Account.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

class _MojangAccountState extends State<MojangAccount> {
  TextEditingController MojangAccountController = TextEditingController();
  TextEditingController MojangPasswdController = TextEditingController();

  bool _obscureText = true;

  _MojangAccountState();

  @override
  void initState() {
    MojangAccountController.text = widget.accountEmail;

    super.initState();
    setState(() {});
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  var title_ = TextStyle(
    fontSize: 20.0,
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("登入 Mojang 帳號"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 3,
        height: MediaQuery.of(context).size.height / 4,
        child: ListView(
          children: [
            Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Mojang 帳號',
                      hintText: '電子郵件',
                      prefixIcon: Icon(Icons.person)),
                  controller: MojangAccountController, // 設定控制器
                ),
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Mojang 密碼',
                      hintText: '密碼',
                      prefixIcon: Icon(Icons.password)),
                  controller: MojangPasswdController,
                  obscureText: _obscureText, // 設定控制器
                ),
                TextButton(
                    onPressed: _toggle,
                    child: Text(_obscureText ? "顯示密碼" : "隱藏密碼")),
                IconButton(
                  icon: Icon(Icons.login),
                  onPressed: () {
                    if (MojangAccountController.text == "" ||
                        MojangPasswdController.text == "") {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("帳號登入資訊"),
                              content: Text("帳號或密碼不能是空的。"),
                              actions: <Widget>[
                                TextButton(
                                  child: Text(i18n.format("gui.confirm")),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          });
                    } else {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("帳號登入資訊"),
                              content: FutureBuilder(
                                  future: MojangHandler.logIn(
                                      MojangAccountController.text,
                                      MojangPasswdController.text),
                                  builder: (BuildContext context,
                                      AsyncSnapshot snapshot) {
                                    if (snapshot.hasError ||
                                        snapshot.data.runtimeType == String) {
                                      if (snapshot.data ==
                                          "ForbiddenOperationException") {
                                        return Text("輸入的帳號或密碼錯誤");
                                      } else {
                                        return StatefulBuilder(builder:
                                            (BuildContext context,
                                                StateSetter setState) {
                                          return Column(
                                            children: [
                                              Text("發生未知錯誤"),
                                              Text(snapshot.error.toString()),
                                            ],
                                          );
                                        });
                                      }
                                    } else if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      var data = snapshot.data;

                                      String UUID =
                                          data["selectedProfile"]["id"];
                                      String UserName =
                                          data["selectedProfile"]["name"];
                                      String Token = data["accessToken"];

                                      Account.add(AccountType.mojang, Token,
                                          UUID, UserName,
                                          email: data["user"]["username"]);

                                      if (Account.getIndex() == -1) {
                                        Account.setIndex(0);
                                      }

                                      return Text("帳號新增成功\n\n玩家名稱: " +
                                          UserName +
                                          "\n玩家 UUID:" +
                                          UUID);
                                    } else {
                                      return SizedBox(
                                        child: Center(
                                          child: Column(
                                            children: <Widget>[
                                              RWLLoading(),
                                              SizedBox(height: 10),
                                              Text("處理中，請稍後...")
                                            ],
                                          ),
                                        ),
                                        height: 80,
                                        width: 100,
                                      );
                                    }
                                  }),
                              actions: <Widget>[
                                TextButton(
                                  child: Text(i18n.format("gui.confirm")),
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
                Text(i18n.format("gui.login"))
              ],
            )
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.close_sharp),
          tooltip: i18n.format("gui.close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class MojangAccount extends StatefulWidget {
  final String accountEmail;
  const MojangAccount({this.accountEmail = ''});

  @override
  _MojangAccountState createState() => _MojangAccountState();
}
