import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/CheckDialog.dart';
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';

import '../main.dart';
import 'MSOauth2Login.dart';
import 'MojangAccount.dart';

var java_path;

class AccountScreen_ extends State<AccountScreen> {
  late int choose_index;

  @override
  void initState() {
    choose_index = -1;
    choose_index = account.GetIndex();
    super.initState();
    setState(() {});
  }

  var title_ = TextStyle(
    fontSize: 20.0,
  );

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text(i18n.Format("account.title")),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: i18n.Format("gui.back"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => new LauncherHome()),
            );
          },
        ),
      ),
      body: Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          child: Column(children: [
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
                style: new ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green)),
                onPressed: () {
                  Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => MojangAccount()),
                  );
                },
                child: Text(
                  i18n.Format("account.add.mojang.title"),
                  textAlign: TextAlign.center,
                  style: title_,
                )),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
              style: new ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.green)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MSLoginWidget(
                      builder: (BuildContext context, Client httpClient) {
                    return Center(
                      child: Text(
                        '成功登入微軟帳號',
                      ),
                    );
                  }),
                );
              },
              child: Text(
                i18n.Format("account.add.microsoft.title"),
                textAlign: TextAlign.center,
                style: title_,
              ),
            ),
            Text(
              "\n${i18n.Format("account.minecraft.title")}\n",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25.0,
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (account.getCount(account.Mojang) != 0) {
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        return ListTile(
                            tileColor: choose_index == index
                                ? Colors.black12
                                : Theme.of(context).scaffoldBackgroundColor,
                            onTap: () {
                              choose_index = index;
                              account.SetIndex(index);
                              account.SetType(account.Mojang);
                              setState(() {});
                            },
                            title: Text(
                                account.getByIndex(
                                    account.Mojang, index)["UserName"],
                                textAlign: TextAlign.center),
                            leading: Image.network(
                              'https://minotar.net/helm/${account.getByIndex("mojang", index)["UUID"]}/40.png',
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                    child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded
                                              .toInt() /
                                          loadingProgress.expectedTotalBytes!
                                              .toInt()
                                      : null,
                                ));
                              },
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              tooltip: "刪除帳號",
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return CheckDialog(
                                          title: "刪除帳號",
                                          content: "您確定要刪除此帳號嗎？ (此動作將無法復原)",
                                          onPressedOK: () {
                                            Navigator.of(context).pop();
                                            account.RemoveByIndex(
                                                "mojang", index);
                                            setState(() {});
                                          });
                                    });
                              },
                            ));
                      },
                      itemCount: account.getCount("mojang"),
                    );
                  } else {
                    return Container(
                      child: Text("找不到帳號", style: TextStyle(fontSize: 30)),
                    );
                  }
                },
              ),
            ),
          ])),
    );
  }
}

class AccountScreen extends StatefulWidget {
  @override
  AccountScreen_ createState() => AccountScreen_();
}
