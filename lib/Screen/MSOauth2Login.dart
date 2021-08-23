/*
The code here is referenced from https://codelabs.developers.google.com/codelabs/flutter-MS-graphql-client
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/Account/Account.dart';
import 'package:rpmlauncher/Account/MSAccountHandler.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:url_launcher/url_launcher.dart';

final _authorizationEndpoint =
    Uri.parse('https://login.live.com/oauth20_authorize.srf');
final _tokenEndpoint = Uri.parse('https://login.live.com/oauth20_token.srf');

class MSLoginWidget extends StatefulWidget {
  @override
  _MSLoginState createState() => _MSLoginState();
}

typedef AuthenticatedBuilder = Widget Function(
    BuildContext context, oauth2.Client client);

class _MSLoginState extends State<MSLoginWidget> {
  HttpServer? _redirectServer;
  @override
  Widget build(BuildContext context) {
    return Center(
        child: AlertDialog(
      title: Text("提示訊息 - 登入您的 Microsoft 帳號 ", textAlign: TextAlign.center),
      content: Text(
        "點選 ${i18n.Format("gui.ok")} 後，將會使用預設瀏覽器開啟網頁\n該網頁為微軟官方登入介面，請在網頁登入微軟帳號\n登入完成後請回到此啟動器",
        textAlign: TextAlign.center,
        style: new TextStyle(fontSize: 20),
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () async {
              Future<Client> LogIn() async {
                await _redirectServer?.close();
                _redirectServer = await HttpServer.bind('localhost', 0);
                return await _getOAuth2Client(Uri.parse(
                    'http://localhost:${_redirectServer!.port}/rpmlauncher-auth'));
              }

              Navigator.pop(context);
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return FutureBuilder(
                        future: LogIn(),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            return FutureBuilder(
                                future: MSAccountHandler().Authorization(
                                    snapshot.data.credentials.accessToken),
                                builder: (context, AsyncSnapshot snapshot) {
                                  if (snapshot.hasData) {
                                    List data = snapshot.data;
                                    if (data.length > 0) {
                                      Map Account_ = data[0];
                                      var UUID =
                                          Account_["selectedProfile"]["id"];
                                      var UserName =
                                          Account_["selectedProfile"]["name"];

                                      account.Add(
                                          account.Microsoft,
                                          Account_['accessToken'],
                                          UUID,
                                          UserName,
                                          null);

                                      if (account.getIndex() == -1) {
                                        account.SetIndex(0);
                                      }

                                      return AlertDialog(
                                        title: Text("登入成功"),
                                        actions: [OkClose()],
                                      );
                                    } else {
                                      return AlertDialog(
                                        title: Text("錯誤資訊 - 登入失敗"),
                                        content: Text(
                                            "此 Microsoft 帳號沒有綁定 Minecraft 帳號，或者發生未知錯誤。"),
                                        actions: [OkClose()],
                                      );
                                    }
                                  } else {
                                    return AlertDialog(
                                      title: Text("正在處理登入資料中..."),
                                      content: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: 10,
                                          ),
                                          CircularProgressIndicator(),
                                          SizedBox(
                                            height: 10,
                                          )
                                        ],
                                      ),
                                    );
                                  }
                                });
                          } else {
                            return AlertDialog(
                              title: Text("正在等待使用者完成登入..."),
                            );
                          }
                        });
                  });
            },
            child: Text(i18n.Format("gui.ok")),
          ),
        )
      ],
    ));
  }

  Future<oauth2.Client> _getOAuth2Client(Uri redirectUrl) async {
    var grant = oauth2.AuthorizationCodeGrant(
      "b7df55b4-300f-4409-8ea9-a172f844aa15", //Client ID
      _authorizationEndpoint,
      _tokenEndpoint,
      httpClient: _JsonAcceptingHttpClient(),
    );
    var authorizationUrl = grant.getAuthorizationUrl(redirectUrl,
        scopes: ['XboxLive.signin', 'offline_access']);
    authorizationUrl = Uri.parse(
        "${authorizationUrl.toString()}&cobrandid=8058f65d-ce06-4c30-9559-473c9275a65d");
    await _redirect(authorizationUrl);
    var responseQueryParameters = await _listen();
    var client =
        await grant.handleAuthorizationResponse(responseQueryParameters);
    return client;
  }

  Future<void> _redirect(authorizationUrl) async {
    var url = authorizationUrl.toString();
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("Can't open the url $url");
    }
  }

  Future<Map<String, String>> _listen() async {
    var request = await _redirectServer!.first;
    var params = request.uri.queryParameters;
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain');
    request.response.writeln('驗證完畢，請回到 RPMLauncher 內。');
    await request.response.close();
    await _redirectServer!.close();
    _redirectServer = null;
    return params;
  }
}

class _JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}
