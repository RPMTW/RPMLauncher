import 'dart:convert';

import 'package:rpmlauncher/Utility/utility.dart';

class MSAccountHandler {
  Future<String> AuthorizationXBL(accessToken) async {
    // Authenticate with XBox Live
    Map map = {
      "Properties": {
        "AuthMethod": "RPS",
        "SiteName": "user.auth.xboxlive.com",
        "RpsTicket": "d=${accessToken}"
      },
      "RelyingParty": "http://auth.xboxlive.com",
      "TokenType": "JWT"
    };
    String url = 'https://user.auth.xboxlive.com/user/authenticate';
    String body = await utility.apiRequest(url, map);
    print(body);
    return body;
  }
}
