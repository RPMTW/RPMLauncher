import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/Utility/Account.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

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
        title: Text("管理Minecraft帳號"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: i18n().Format("gui.back"),
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
            ElevatedButton(
              style: new ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                onPressed: () {
                  Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => MojangAccount()),
                  );
                },
                child: Text(i18n().Format("account.add.mojang.title"),
                  textAlign: TextAlign.center,
                  style: title_,
                )),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
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
                i18n().Format("account.add.microsoft.title"),
                textAlign: TextAlign.center,
                style: title_,
              ),
            ),
            Text(
              "\nMinecraft 帳號\n",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25.0,
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (account.GetAll().isNotEmpty) {
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        return ListTile(
                          tileColor: choose_index == index
                              ? Colors.black12
                              : Theme.of(context).scaffoldBackgroundColor,
                          onTap: () {
                            choose_index = index;
                            account.SetIndex(index);
                            setState(() {});
                          },
                          title: Center(
                            child: Text(account.GetByIndex(
                                "mojang", index)["UserName"]),
                          ),
                        );
                      },
                      itemCount: account.GetAll()["mojang"].keys.length,
                    );
                  } else {
                    return Container();
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
