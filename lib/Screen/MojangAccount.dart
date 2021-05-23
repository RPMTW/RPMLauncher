import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../main.dart';

Future<String> apiRequest(String url, Map jsonMap) async {
  HttpClient httpClient = new HttpClient();
  HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
  request.headers.set('content-type', 'application/json');
  request.add(utf8.encode(json.encode(jsonMap)));
  HttpClientResponse response = await request.close();
  String reply = await response.transform(utf8.decoder).join();
  httpClient.close();
  return reply;
}

class MojangAccount_ extends State<MojangAccount> {
  var Password;
  var Account;

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
    Map<String, dynamic> body = jsonDecode(await apiRequest(url, map));
    return body;
  }

  bool _obscureText = true;
  late String _password;

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
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
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new MyApp()),
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
                                  title: const Text("帳號登入資訊"),
                                  content: FutureBuilder(
                                      future: aaa(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot snapshot) {
                                        if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          var data = snapshot.data;
                                          return Text(data);
                                        } else {
                                          return Center(
                                              child:
                                                  CircularProgressIndicator());
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
