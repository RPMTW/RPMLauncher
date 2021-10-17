import 'package:flutter/material.dart';
import 'package:rpmlauncher/Account/MojangAccountHandler.dart';
import 'package:rpmlauncher/Model/Account.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
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
                  controller: emailController, // 設定控制器
                ),
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Mojang 密碼',
                      hintText: '密碼',
                      prefixIcon: Icon(Icons.password)),
                  controller: passwdController,
                  obscureText: _obscureText, // 設定控制器
                ),
                TextButton(
                    onPressed: _toggle,
                    child: Text(_obscureText ? "顯示密碼" : "隱藏密碼")),
                IconButton(
                  icon: Icon(Icons.login),
                  onPressed: () {
                    if (emailController.text == "" ||
                        passwdController.text == "") {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("帳號登入資訊"),
                              content: Text("帳號或密碼不能是空的。"),
                              actions: <Widget>[
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
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("帳號登入資訊"),
                              content: FutureBuilder(
                                  future: MojangHandler.logIn(
                                      emailController.text,
                                      passwdController.text),
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

                                      String uuid =
                                          data["selectedProfile"]["id"];
                                      String userName =
                                          data["selectedProfile"]["name"];
                                      String token = data["accessToken"];

                                      Account.add(AccountType.mojang, token,
                                          uuid, userName,
                                          email: data["user"]["username"]);

                                      if (Account.getIndex() == -1) {
                                        Account.setIndex(0);
                                      }

                                      return Text("帳號新增成功\n\n玩家名稱: " +
                                          userName +
                                          "\n玩家 UUID:" +
                                          uuid);
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
                Text(I18n.format("gui.login"))
              ],
            )
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.close_sharp),
          tooltip: I18n.format("gui.close"),
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
