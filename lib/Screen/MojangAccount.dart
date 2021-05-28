import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:xdg_directories/xdg_directories.dart';

import 'Account.dart';

Future<String> apiRequest(String url, Map jsonMap) async {
  HttpClient httpClient = new HttpClient();
  HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
  request.headers.set('content-type', 'application/json');
  request.add(utf8.encode(json.encode(jsonMap)));
  HttpClientResponse response = await request.close();
  var reply = '';
  reply = await response.transform(utf8.decoder).join();
  httpClient.close();
  return reply;
}

class MojangAccount_ extends State<MojangAccount> {

  late io.Directory AccountFolder;
  late io.File AccountFile;
  late Map Account;

  @override
  void initState() {
    AccountFolder = configHome;
    AccountFile = io.File(
        join(AccountFolder.absolute.path, "RPMLauncher", "accounts.json"));
    Account = json.decode(AccountFile.readAsStringSync());
    if (Account["mojang"]==null){
      Account["mojang"]=[];
    }

    super.initState();
    setState(() {});
  }

  var Password;

  var MojangAccountController = TextEditingController();
  var MojangPasswdController = TextEditingController();

  Future aaa() async {
    String url = 'https://authserver.mojang.com/authenticate';
    Map map = {
      'agent': {'name': 'Minecraft', "version": 1},
      "username": MojangAccountController.text,
      "password": MojangPasswdController.text,
      "requestUser": true
    };
    var body = await jsonDecode(await apiRequest(url, map));
    print(body);
    return body;
  }

  bool _obscureText = true;
  late String _password;

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  var title_ = TextStyle(
    fontSize: 20.0,
  );

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("登入 Mojang 帳號"),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () {
            AccountFile.writeAsStringSync(json.encode(Account));
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => AccountScreen()),
            );
          },
        ),
      ),
      body: Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          child: ListView(
            children: [
              Center(
                child: Expanded(
                    child: Column(
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
                          labelText: 'Mojang 帳號密碼',
                          hintText: '密碼',
                          prefixIcon: Icon(Icons.password)),
                      controller: MojangPasswdController,
                      onChanged: (val) => _password = val,
                      obscureText: _obscureText, // 設定控制器
                    ),
                    TextButton(
                        onPressed: _toggle,
                        child: Text(_obscureText ? "顯示密碼" : "隱藏密碼")),
                    IconButton(
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
                                      child: const Text('確認'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              });
                        } else {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text("帳號登入資訊"),
                                  content: FutureBuilder(
                                      future: aaa(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot snapshot) {
                                        if (snapshot.hasData &&
                                            snapshot.data != null &&
                                            !snapshot.data.toString().startsWith("{error:")) {
                                          var data = snapshot.data;
                                            if (Account["mojang"]== null){
                                              Account["mojang"]=[];
                                            }
                                            try {
                                              Account["mojang"].add(data);
                                            }catch(e){
                                              Account["mojang"]=[data];
                                            }

                                          return Text("帳號新增成功\n\n玩家名稱: " +
                                              data["selectedProfile"]["name"] +
                                              "\n玩家 UUID:" +
                                              data["selectedProfile"]["id"]);
                                        } else {
                                          return SizedBox(
                                            child: Center(
                                              child: Column(
                                                children: <Widget>[
                                                  CircularProgressIndicator(),
                                                  Text(
                                                      "處理中，請稍後...\n\n如果處理超過10秒鐘\n可能造成的原因：\n1.無法連接網路\n2.無法連結Mojang伺服器\n3.你輸入的帳號或密碼錯誤\n4.你的帳號一直重複登入導致被Mojang暫時Ban")
                                                ],
                                              ),
                                            ),
                                            height: 250,
                                            width: 100,
                                          );
                                        }
                                      }),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('確認'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              });
                        }
                      },
                      icon: Icon(Icons.login),
                      tooltip: "登入",
                    ),
                    Text("登入")
                  ],
                )),
              )
            ],
          )),
    );
  }
}

class MojangAccount extends StatefulWidget {
  @override
  MojangAccount_ createState() => MojangAccount_();
}
