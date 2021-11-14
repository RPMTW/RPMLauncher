/*
The code here is referenced from https://codelabs.developers.google.com/codelabs/flutter-MS-graphql-client
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/Account/MSAccountHandler.dart';
import 'package:rpmlauncher/Model/Game/Account.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

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
    Future<Client> logIn() async {
      await _redirectServer?.close();
      _redirectServer = await HttpServer.bind('127.0.0.1', 5020);
      var authenticatedHttpClient = await _getOAuth2Client(
          Uri.parse('http://127.0.0.1:5020/rpmlauncher-auth'));
      return authenticatedHttpClient;
    }

    return FutureBuilder(
        future: logIn(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            oauth2.Client _client = snapshot.data;
            return FutureBuilder(
                future: MSAccountHandler.authorization(
                    _client.credentials.accessToken),
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    List data = snapshot.data;
                    if (data.isNotEmpty) {
                      Map accountMap = data[0];
                      String uuid = accountMap["selectedProfile"]["id"];
                      String userName = accountMap["selectedProfile"]["name"];
                      Account.add(AccountType.microsoft,
                          accountMap['accessToken'], uuid, userName,
                          credentials: _client.credentials);

                      if (Account.getIndex() == -1) {
                        Account.setIndex(0);
                      }

                      Account.updateAccountData();

                      return AlertDialog(
                        title: I18nText("account.add.successful"),
                        actions: [OkClose()],
                      );
                    } else {
                      return AlertDialog(
                        title: I18nText("account.add.microsoft.error.unknown"),
                        actions: [OkClose()],
                      );
                    }
                  } else {
                    return AlertDialog(
                      title: I18nText("account.add.microsoft.loading"),
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 10,
                          ),
                          RWLLoading(),
                          SizedBox(
                            height: 10,
                          )
                        ],
                      ),
                    );
                  }
                });
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else {
            return AlertDialog(
              title: I18nText("account.add.microsoft.waiting"),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  RWLLoading(),
                  SizedBox(
                    height: 10,
                  )
                ],
              ),
            );
          }
        });
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
        "${authorizationUrl.toString()}&cobrandid=8058f65d-ce06-4c30-9559-473c9275a65d&prompt=select_account");
    await _redirect(authorizationUrl);
    var responseQueryParameters = await _listen();
    var client =
        await grant.handleAuthorizationResponse(responseQueryParameters);
    return client;
  }

  Future<void> _redirect(authorizationUrl) async {
    var url = authorizationUrl.toString();
    Uttily.openUri(url);
  }

  Future<Map<String, String>> _listen() async {
    var request = await _redirectServer!.first;
    var params = request.uri.queryParameters;
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain; charset=utf-8');
    request.response.writeln(I18n.format('account.add.microsoft.html'));
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
