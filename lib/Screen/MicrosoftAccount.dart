import 'package:flutter/material.dart';

import '../main.dart';

class MicrosoftAccount_ extends State<MicrosoftAccount> {
  var MicrosoftAccountController = TextEditingController();
  var MicrosoftPasswdController = TextEditingController();

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
        title: new Text("登入 Microsoft 帳號"),
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
                              labelText: 'Microsoft 帳號',
                              hintText: '電子郵件',
                              prefixIcon: Icon(Icons.person)),
                          controller: MicrosoftAccountController, // 設定控制器
                        ),
                        TextField(
                          decoration: InputDecoration(
                              labelText: 'Microsoft 帳號密碼',
                              hintText: '密碼',
                              prefixIcon: Icon(Icons.password)),
                          controller: MicrosoftPasswdController,
                          onChanged: (val) => _password = val,
                          obscureText: _obscureText, // 設定控制器
                        ),
                        TextButton(
                            onPressed: _toggle,
                            child: Text(_obscureText ? "顯示密碼" : "隱藏密碼")),
                        IconButton(
                          onPressed: () {},
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

class MicrosoftAccount extends StatefulWidget {
  @override
  MicrosoftAccount_ createState() => MicrosoftAccount_();
}
