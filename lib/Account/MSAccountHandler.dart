import 'dart:convert';
import 'package:http/http.dart' as http;

class MSAccountHandler {
  /*
  API Docs: https://wiki.vg/Microsoft_Authentication_Scheme
  M$ Oauth2: https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow
  M$ Register Application: https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app
   */
  Future<List> Authorization(String accessToken) async {
    var headers = {
      'Content-Type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://rear-end.a102009102009.repl.co/rpmlauncher/api/microsof-auth?accessToken=$accessToken'));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String body = await response.stream.bytesToString();
      return json.decode(body);
    } else {
      print(response.reasonPhrase);
      return [];
    }
  }
}
