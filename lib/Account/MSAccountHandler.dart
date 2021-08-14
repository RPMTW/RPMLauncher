import 'dart:convert';
import 'package:http/http.dart' as http;

class MSAccountHandler {
  /*
  API Docs: https://wiki.vg/Microsoft_Authentication_Scheme
  M$ Oauth2: https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow
  M$ Register Application: https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app
   */
  Future AuthorizationXBL(String accessToken) async {
    //Authenticate with XBL
    print(accessToken);
    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    var request = http.Request(
        'POST', Uri.parse('https://user.auth.xboxlive.com/user/authenticate'));
    request.body = json.encode({
      "Properties": {
        "AuthMethod": "RPS",
        "SiteName": "user.auth.xboxlive.com",
        "RpsTicket": "d=${accessToken}"
      },
      "RelyingParty": "http://auth.xboxlive.com",
      "TokenType": "JWT"
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      Map data = json.decode(await response.stream.bytesToString());
      String xblToken = data["Token"];
      String UserHash = data["DisplayClaims"]["xui"][0]["uhs"];
      await AuthorizationXSTS(xblToken, UserHash);
    } else {
      print(response.reasonPhrase);
    }
  }

  Future AuthorizationXSTS(String xblToken, String UserHash) async {
    //Authenticate with XSTS

    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    var request = http.Request(
        'POST', Uri.parse('https://xsts.auth.xboxlive.com/xsts/authorize'));
    request.body = json.encode({
      "Properties": {
        "SandboxId": "RETAIL",
        "UserTokens": [xblToken]
      },
      "RelyingParty": "rp://api.minecraftservices.com/",
      "TokenType": "JWT"
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      Map data = json.decode(await response.stream.bytesToString());
      String xstsToken = data["Token"];
      String UserHash = data["DisplayClaims"]["xui"][0]["uhs"];
      await AuthorizationMinecraft(xstsToken, UserHash);
    } else if (response.statusCode == 401) {
      Map data = json.decode(await response.stream.bytesToString());
      int XErr = data["XErr"];

      if (XErr == 2148916233) {
        //不是Xobx的帳號
        //To do
      } else if (XErr == 2148916238) {
        //是未成年的帳號 (18歲以下)
        //To do
      }
    } else {
      print(response.reasonPhrase);
    }
  }

  Future AuthorizationMinecraft(String xstsToken, String UserHash) async {
    //Authenticate with Minecraft

    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    var request = http.Request(
        'POST',
        Uri.parse(
            'https://api.minecraftservices.com/authentication/login_with_xbox'));
    request.body =
        json.encode({"identityToken": "XBL3.0 x=${UserHash};${xstsToken}"});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      Map data = json.decode(await response.stream.bytesToString());
      String userName = data["username"];
      String MCAccessToken = data["access_token"];
      await CheckingGameOwnership(MCAccessToken);
    } else {
      print(response.reasonPhrase);
    }
  }

  Future CheckingGameOwnership(String accessToken) async {
    //Checking Game Ownership

    var headers = {
      'Authorization': 'Bearer $accessToken',
    };
    var request = http.Request('POST',
        Uri.parse('https://api.minecraftservices.com/entitlements/mcstore'));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      Map data = json.decode(await response.stream.bytesToString());
      List Items = data["items"];
      if (Items == 0) {
        //Ttems 為0代表該帳號沒有遊玩Minecraft的權限
      } else {
        // To do : 成功登入帳號執行的內容
      }
    } else {
      print(response.reasonPhrase);
    }
  }
}
