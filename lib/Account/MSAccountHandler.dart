import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class MSAccountHandler {
  Future<Map> getAuthorizationToken(Secret, Code, redirectUrl) async {
    // Authorization Code -> Token
    var ClientID = "b7df55b4-300f-4409-8ea9-a172f844aa15";

    Map<String, String> map = {
      'client_id': ClientID,
      "client_secret": Secret,
      "code": Code,
      "grant_type": "authorization_code",
      "redirect_uri": redirectUrl.toString()
    };

    String url = 'https://login.live.com/oauth20_token.srf';

    Map<String, String> headers = new Map();
    headers["Content-Type"] = "application/x-www-form-urlencoded";
    var parts = [];
    map.forEach((key, value) {
      parts.add('${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}');
    });
    var formData = parts.join('&');

    print(formData);
    Response response =
        await http.post(Uri.parse(url), headers: headers, body: formData);
    Map body = await jsonDecode(response.body);
    print(body);
    return body;
  }
}
