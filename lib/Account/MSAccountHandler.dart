import 'dart:convert';

import 'package:http/http.dart' as http;

class MSAccountHandler {
  Future<String> AuthorizationXBL(accessToken) async {
    // Authenticate with XBox Live
    String url = 'https://user.auth.xboxlive.com/user/authenticate';

    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json'
      },
      body: jsonEncode({
        "Properties": {
          "AuthMethod": "RPS",
          "SiteName": "user.auth.xboxlive.com",
          "RpsTicket": "d=${accessToken}"
        },
        "RelyingParty": "http://auth.xboxlive.com",
        "TokenType": "JWT"
      }),
    );

    print(response.body);
    return response.body;
  }
}
