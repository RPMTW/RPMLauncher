/*
The code here is referenced from https://codelabs.developers.google.com/codelabs/flutter-MS-graphql-client
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/account/microsoft_account_handler.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/OkClose.dart';
import 'package:rpmlauncher/ui/widget/rwl_loading.dart';

/// 僅在測試中使用
@visibleForTesting
Future<Client> Function()? microsoftOauthMock;

final _authorizationEndpoint =
    Uri.parse('https://login.live.com/oauth20_authorize.srf');
final _tokenEndpoint = Uri.parse('https://login.live.com/oauth20_token.srf');

class MSLoginWidget extends StatefulWidget {
  @override
  State<MSLoginWidget> createState() => _MSLoginState();
}

typedef AuthenticatedBuilder = Widget Function(
    BuildContext context, oauth2.Client client);

class _MSLoginState extends State<MSLoginWidget> {
  late final HttpServer _redirectServer;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: microsoftOauthMock?.call() ?? logIn(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            oauth2.Client client = snapshot.data;
            return StreamBuilder<MicrosoftAccountStatus>(
                stream: MSAccountHandler.authorization(client.credentials),
                initialData: MicrosoftAccountStatus.xbl,
                builder: (context, snapshot) {
                  final MicrosoftAccountStatus status = snapshot.data!;

                  if (status.isError) {
                    return AlertDialog(
                      title: I18nText.errorInfoText(),
                      content: Text(status.stateName),
                      actions: const [OkClose()],
                    );
                  } else {
                    return AlertDialog(
                      title: I18nText('account.add.microsoft.state.title'),
                      content: Text(status.stateName),
                      actions: status == MicrosoftAccountStatus.successful
                          ? [const OkClose()]
                          : null,
                    );
                  }
                });
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else {
            return AlertDialog(
              title: I18nText('account.add.microsoft.waiting'),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
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

  Future<Client> logIn() async {
    _redirectServer = await HttpServer.bind('127.0.0.1', 5020);

    return await _getOAuth2Client(
        Uri.parse('http://127.0.0.1:5020/rpmlauncher-auth'));
  }

  Future<oauth2.Client> _getOAuth2Client(Uri redirectUrl) async {
    AuthorizationCodeGrant grant = oauth2.AuthorizationCodeGrant(
      LauncherInfo.microsoftClientID, //Client ID
      _authorizationEndpoint,
      _tokenEndpoint,
      httpClient: _JsonAcceptingHttpClient(),
    );
    Uri authorizationUrl = grant.getAuthorizationUrl(redirectUrl,
        scopes: ['XboxLive.signin', 'offline_access']);
    authorizationUrl = Uri.parse(
        '${authorizationUrl.toString()}&cobrandid=8058f65d-ce06-4c30-9559-473c9275a65d&prompt=select_account');
    await Util.openUri(authorizationUrl.toString());
    final responseQueryParameters = await _listenParameters();

    return await grant.handleAuthorizationResponse(responseQueryParameters);
  }

  Future<Map<String, String>> _listenParameters() async {
    final request = await _redirectServer.first;
    final params = request.uri.queryParameters;
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain; charset=utf-8');
    request.response.writeln(I18n.format('account.add.microsoft.html'));
    await request.response.close();
    await _redirectServer.close();

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
