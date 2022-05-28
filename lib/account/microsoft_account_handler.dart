import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/launcher/APIs.dart';
import 'package:rpmlauncher/model/account/Account.dart';
import 'package:rpmlauncher/model/account/MicrosoftEntitlements.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/util/LauncherInfo.dart';
import 'package:rpmlauncher/util/Logger.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';
import 'package:uuid/uuid.dart';

enum MicrosoftAccountStatus {
  unknown,
  xbl,
  xsts,
  xstsError,
  isChild,
  bannedCountry,
  noneXboxAccount,
  minecraftAuthorize,
  minecraftAuthorizeError,
  checkingGameOwnership,
  notGameOwnership,
  successful,
}

extension MicrosoftAccountStatusExtension on MicrosoftAccountStatus {
  static Account? _accountData;

  void setAccountData(Account account) {
    _accountData = account;
  }

  Account? getAccountData() => _accountData;

  String get stateName {
    String i18nKey() {
      switch (this) {
        case MicrosoftAccountStatus.xbl:
          return 'account.add.microsoft.state.xbl';
        case MicrosoftAccountStatus.xsts:
          return 'account.add.microsoft.state.xsts';
        case MicrosoftAccountStatus.xstsError:
          return 'account.add.microsoft.state.xstsError';
        case MicrosoftAccountStatus.isChild:
          return 'account.add.microsoft.state.isChild';
        case MicrosoftAccountStatus.bannedCountry:
          return 'account.add.microsoft.state.bannedCountry';
        case MicrosoftAccountStatus.noneXboxAccount:
          return 'account.add.microsoft.state.noneXboxAccount';
        case MicrosoftAccountStatus.minecraftAuthorize:
          return 'account.add.microsoft.state.minecraftAuthorize';
        case MicrosoftAccountStatus.minecraftAuthorizeError:
          return 'account.add.microsoft.state.minecraftAuthorizeError';
        case MicrosoftAccountStatus.checkingGameOwnership:
          return 'account.add.microsoft.state.checkingGameOwnership';
        case MicrosoftAccountStatus.notGameOwnership:
          return 'account.add.microsoft.state.notGameOwnership';
        case MicrosoftAccountStatus.successful:
          return 'account.add.successful';
        case MicrosoftAccountStatus.unknown:
          return 'account.add.microsoft.state.unknown';
        default:
          return 'account.add.microsoft.state.unknown';
      }
    }

    return I18n.format(i18nKey());
  }

  bool get isError {
    switch (this) {
      case MicrosoftAccountStatus.xstsError:
        return true;
      case MicrosoftAccountStatus.isChild:
        return true;
      case MicrosoftAccountStatus.bannedCountry:
        return true;
      case MicrosoftAccountStatus.noneXboxAccount:
        return true;
      case MicrosoftAccountStatus.minecraftAuthorizeError:
        return true;
      case MicrosoftAccountStatus.notGameOwnership:
        return true;
      case MicrosoftAccountStatus.unknown:
        return true;
      default:
        return false;
    }
  }
}

class MSAccountHandler {
  /*
  API Docs: https://wiki.vg/Microsoft_Authentication_Scheme
  M$ Oauth2: https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow
  M$ Register Application: https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app
   */

  static final RPMHttpClient _httpClient = RPMHttpClient(
      baseOptions: BaseOptions(
          contentType: ContentType.json.mimeType,
          validateStatus: (status) => true));

  static Stream<MicrosoftAccountStatus> authorization(
      Credentials credentials) async* {
    try {
      yield MicrosoftAccountStatus.xbl;
      Map xboxLiveData = await _authorizationXBL(credentials.accessToken);
      String xblToken = xboxLiveData["Token"];
      String userHash = xboxLiveData["DisplayClaims"]["xui"][0]["uhs"];

      yield MicrosoftAccountStatus.xsts;
      Response response = await _authorizationXSTS(xblToken, userHash);

      Map? xstsData;

      if (response.statusCode == 200) {
        xstsData = response.data;
      } else if (response.statusCode == 401) {
        Map data = response.data;
        int xError = data["XErr"];
        if (xError == 2148916233) {
          //此微軟帳號沒有Xobx帳號
          yield MicrosoftAccountStatus.noneXboxAccount;
        } else if (xError == 2148916235) {
          /// Xbox在該國家/地區無法使用
          yield MicrosoftAccountStatus.bannedCountry;
        } else if (xError == 2148916238) {
          ///是未成年的帳號 (18歲以下)
          yield MicrosoftAccountStatus.isChild;
        }
        return;
      }

      if (xstsData == null) {
        logger.error(ErrorType.account, response.statusMessage);
        yield MicrosoftAccountStatus.xstsError;
        return;
      }

      String xstsToken = xstsData["Token"];
      String xstsUserHash = xstsData["DisplayClaims"]["xui"][0]["uhs"];

      yield MicrosoftAccountStatus.minecraftAuthorize;
      Map? minecraftAuthorizeData =
          await _authorizationMinecraft(xstsToken, xstsUserHash);

      if (minecraftAuthorizeData == null) {
        MicrosoftAccountStatus.minecraftAuthorizeError;
        return;
      }

      String mcAccessToken = minecraftAuthorizeData["access_token"];

      yield MicrosoftAccountStatus.checkingGameOwnership;
      bool canPlayMinecraft = await _checkingGameOwnership(mcAccessToken);

      if (canPlayMinecraft) {
        Map profileJson = await getProfile(mcAccessToken);

        MicrosoftAccountStatus finishState = MicrosoftAccountStatus.successful;
        finishState.setAccountData(Account(AccountType.microsoft, mcAccessToken,
            profileJson['id'], profileJson['name'],
            credentials: credentials));
        yield finishState;
      } else {
        yield MicrosoftAccountStatus.notGameOwnership;
      }
    } catch (e, stackTrace) {
      logger.error(ErrorType.account, e, stackTrace: stackTrace);
      yield MicrosoftAccountStatus.unknown;
    }
    return;
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
    Map result;

    Future<Map> proxy() async {
      Response response = await _httpClient.get(
          "https://rear-end.a102009102009.repl.co/rpmlauncher/api/microsof-auth-xbl?accessToken=$accessToken");

      if (response.data is Map) {
        return response.data;
      } else {
        return json.decode(response.data.toString());
      }
    }

    if (kTestMode) {
      result = await proxy();
    } else {
      try {
        ProcessResult curlResult = await Process.run(
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
                runInShell: true)
            .timeout(const Duration(seconds: 3));
        result = json.decode(curlResult.stdout.toString());
      } catch (e) {
        /// 如果使用 curl 超出時間限制或其他未知錯誤則改用代理伺服器
        result = await proxy();
      }
    }

    return result;
  }

  static Future<Response> _authorizationXSTS(
      String xblToken, String userHash) async {
    //Authenticate with XSTS

    Response response = await _httpClient.post(
        "https://xsts.auth.xboxlive.com/xsts/authorize",
        data: json.encode({
          "Properties": {
            "SandboxId": "RETAIL",
            "UserTokens": [xblToken]
          },
          "RelyingParty": "rp://api.minecraftservices.com/",
          "TokenType": "JWT"
        }),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }));

    return response;
  }

  static Future<Map?> _authorizationMinecraft(
      String xstsToken, String userHash) async {
    //Authenticate with Minecraft

    Response response = await _httpClient.post(
        "https://api.minecraftservices.com/launcher/login",
        data: json.encode({
          "xtoken": "XBL3.0 x=$userHash;$xstsToken",
          "platform": "PC_LAUNCHER"
        }),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }));

    if (response.statusCode == 200) {
      return response.data;
    } else {
      logger.error(ErrorType.network, response.statusMessage);
    }
    return null;
  }

  static Future<bool> _checkingGameOwnership(String accessToken) async {
    //Checking Game Ownership

    Response response = await _httpClient.get(
        "https://api.minecraftservices.com/entitlements/license?requestId=${const Uuid().v4()}",
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': "application/json"
        }, contentType: ContentType.json.mimeType));

    if (response.statusCode == 200) {
      MicrosoftEntitlements entitlements =
          MicrosoftEntitlements.fromJson(json.encode(response.data));

      return entitlements.canPlayMinecraft;
    } else {
      return false;
    }
  }

  static Future<Map> getProfile(mcAccessToken) async {
    Response response = await _httpClient.get(
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
                actions: const [OkClose()],
              ));
      return data;
    } else {
      return data;
    }
  }
}
