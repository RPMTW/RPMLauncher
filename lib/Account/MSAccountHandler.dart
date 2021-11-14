import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Model/Game/MicrosoftEntitlements.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/main.dart';
import 'package:uuid/uuid.dart';

class MSAccountHandler {
  /*
  API Docs: https://wiki.vg/Microsoft_Authentication_Scheme
  M$ Oauth2: https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow
  M$ Register Application: https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app
   */

  static Dio _dio = Dio(BaseOptions(
    contentType: ContentType.json.mimeType,
  ));

  static Future<List> authorization(String accessToken) async {
    Map xboxLiveData = await _authorizationXBL(accessToken);
    String xblToken = xboxLiveData["Token"];
    String userHash = xboxLiveData["DisplayClaims"]["xui"][0]["uhs"];
    return await _authorizationXSTS(xblToken, userHash);
  }

  static Future<bool> validate(String accessToken) async {
    /*
    驗證微軟帳號的Token是否有效
    */

    var headers = {'Authorization': 'Bearer $accessToken'};
    var request = http.Request('GET', Uri.parse(microsoftProfileAPI));
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    return response.statusCode == 200;
  }

  static Future<Map> _authorizationXBL(String accessToken) async {
    ProcessResult result = await Process.run(
        'curl',
        [
          "https://user.auth.xboxlive.com/user/authenticate",
          "--location",
          "--request",
          "POST",
          "--header",
          "Content-Type: application/json",
          "--data-raw",
          json.encode({
            "Properties": {
              "AuthMethod": "RPS",
              "SiteName": "user.auth.xboxlive.com",
              "RpsTicket": "d=$accessToken"
            },
            "RelyingParty": "http://auth.xboxlive.com",
            "TokenType": "JWT"
          }),
        ],
        runInShell: true);

    return json.decode(result.stdout.toString());
  }

  static Future<List> _authorizationXSTS(
      String xblToken, String userHash) async {
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
      String _userHash = data["DisplayClaims"]["xui"][0]["uhs"];
      return await _authorizationMinecraft(xstsToken, _userHash);
    } else if (response.statusCode == 401) {
      Map data = json.decode(await response.stream.bytesToString());
      int xError = data["XErr"];
      if (xError == 2148916233) {
        //不是Xobx的帳號
        //To do
      } else if (xError == 2148916238) {
        //是未成年的帳號 (18歲以下)
        //To do
      }
      return [];
    } else {
      logger.error(ErrorType.network, response.reasonPhrase);
      return [];
    }
  }

  static Future<List> _authorizationMinecraft(
      String xstsToken, String userHash) async {
    //Authenticate with Minecraft

    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    var request = http.Request(
        'POST', Uri.parse('https://api.minecraftservices.com/launcher/login'));
    request.body = json.encode(
        {"xtoken": "XBL3.0 x=$userHash;$xstsToken", "platform": "PC_LAUNCHER"});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      Map data = json.decode(await response.stream.bytesToString());
      // String userName = data["username"];
      String mcAccessToken = data["access_token"];
      return await _checkingGameOwnership(mcAccessToken);
    } else {
      logger.error(ErrorType.network, response.reasonPhrase);
      return [];
    }
  }

  static Future<List> _checkingGameOwnership(String accessToken) async {
    //Checking Game Ownership

    Response response = await _dio.get(
        "https://api.minecraftservices.com/entitlements/license?requestId=${Uuid().v4()}",
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': "application/json"
        }, contentType: ContentType.json.mimeType));

    if (response.statusCode == 200) {
      MicrosoftEntitlements entitlements =
          MicrosoftEntitlements.fromJson(json.encode(response.data));

      if (entitlements.canPlayMinecraft) {
        Map profileJson = await getProfile(accessToken);

        Map profile = {'name': profileJson['name'], 'id': profileJson['id']};
        return [
          {
            "accessToken": accessToken,
            "selectedProfile": profile,
            "availableProfile": [profile]
          }
        ];
      } else {
        return [];
      }
    } else {
      return [];
    }
  }

  static Future<Map> getProfile(mcAccessToken) async {
    Response response = await _dio.get(
        "https://api.minecraftservices.com/minecraft/profile",
        options: Options(
            headers: {'Authorization': "Bearer $mcAccessToken"},
            responseType: ResponseType.json));
    Map data = response.data;

    if (data['error'].toString() == "NOT_FOUND") {
      await showDialog(
          context: navigator.context,
          builder: (context) => AlertDialog(
                title: I18nText.errorInfoText(),
                content: I18nText("account.add.microsoft.error.xbox_game_pass"),
                actions: [OkClose()],
              ));
      return data;
    } else {
      return data;
    }
  }
}
