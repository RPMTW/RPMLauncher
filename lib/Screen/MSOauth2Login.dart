/*
The code here is referenced from https://codelabs.developers.google.com/codelabs/flutter-MS-graphql-client
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:url_launcher/url_launcher.dart';

final _authorizationEndpoint =
    Uri.parse('https://login.live.com/oauth20_authorize.srf');
final _tokenEndpoint = Uri.parse('https://login.live.com/oauth20_token.srf');

class MSLoginWidget extends StatefulWidget {
  const MSLoginWidget({
    required this.builder,
  });

  final AuthenticatedBuilder builder;

  @override
  _MSLoginState createState() => _MSLoginState();
}

typedef AuthenticatedBuilder = Widget Function(
    BuildContext context, oauth2.Client client);

class _MSLoginState extends State<MSLoginWidget> {
  HttpServer? _redirectServer;
  oauth2.Client? _client;

  @override
  Widget build(BuildContext context) {
    final client = _client;
    if (client != null) {
      return widget.builder(context, client);
    }
    return Center(
        child: AlertDialog(
      title: Text("提示訊息", textAlign: TextAlign.center),
      content: Text(
          "點選 ${i18n().Format("gui.ok")} 後，將會使用預設瀏覽器開啟網頁\n該網頁為微軟官方登入介面，請在網頁登入微軟帳號\n直到出現 \"Authenticated! You can close this tab.\"\n再回到此啟動器即可完成登入帳號",
          textAlign: TextAlign.center,style: new TextStyle(fontSize: 20),),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () async {
              await _redirectServer?.close();
              // Bind to an ephemeral port on localhost
              _redirectServer = await HttpServer.bind('localhost', 0);
              var authenticatedHttpClient = await _getOAuth2Client(Uri.parse(
                  'http://localhost:${_redirectServer!.port}/rpmlauncher-auth'));
              setState(() {
                _client = authenticatedHttpClient;
              });
            },
            child: Text(i18n().Format("gui.ok")),
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
    print(authorizationUrl);
    await _redirect(authorizationUrl);
    var responseQueryParameters = await _listen();
    var client =
        await grant.handleAuthorizationResponse(responseQueryParameters);
    print(responseQueryParameters); //返回的參數
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
    request.response.writeln('Authenticated! You can close this tab.');
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
