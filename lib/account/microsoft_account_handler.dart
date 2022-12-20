import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/model/account/Account.dart';
import 'package:rpmlauncher/model/account/microsoft_entitlements.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/OkClose.dart';
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
  successful;

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
      String xblToken = xboxLiveData['Token'];
      String userHash = xboxLiveData['DisplayClaims']['xui'][0]['uhs'];

      yield MicrosoftAccountStatus.xsts;
      Response response = await _authorizationXSTS(xblToken, userHash);

      Map? xstsData;

      if (response.statusCode == 200) {
        xstsData = response.data;
      } else if (response.statusCode == 401) {
        Map data = response.data;
        int xError = data['XErr'];
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
        logger.error(ErrorType.authorization, response.statusMessage);
        yield MicrosoftAccountStatus.xstsError;
        return;
      }

      String xstsToken = xstsData['Token'];
      String xstsUserHash = xstsData['DisplayClaims']['xui'][0]['uhs'];

      yield MicrosoftAccountStatus.minecraftAuthorize;
      Map? minecraftAuthorizeData =
          await _authorizationMinecraft(xstsToken, xstsUserHash);

      if (minecraftAuthorizeData == null) {
        MicrosoftAccountStatus.minecraftAuthorizeError;
        return;
      }

      String mcAccessToken = minecraftAuthorizeData['access_token'];

      yield MicrosoftAccountStatus.checkingGameOwnership;
      bool canPlayMinecraft = await _checkingGameOwnership(mcAccessToken);

      if (canPlayMinecraft) {
        Map profileJson = await getProfile(mcAccessToken);

        final account = Account(AccountType.microsoft, mcAccessToken,
            profileJson['id'], profileJson['name'],
            credentials: credentials);
        await account.save();

        yield MicrosoftAccountStatus.successful;
      } else {
        yield MicrosoftAccountStatus.notGameOwnership;
      }
    } catch (e, stackTrace) {
      logger.error(ErrorType.authorization, e, stackTrace: stackTrace);
      yield MicrosoftAccountStatus.unknown;
    }
    return;
  }

  /*
    Verify the microsoft account is able to play minecraft
    */
  static Future<bool> validate(String accessToken) async {
    final Response response = await _httpClient.get(
        'https://api.minecraftservices.com/minecraft/profile',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}));

    return response.statusCode == 200;
  }

  static Future<Map> _authorizationXBL(String accessToken) async {
    final Response response = await _httpClient.post(
      'https://user.auth.xboxlive.com/user/authenticate',
      data: json.encode({
        'Properties': {
          'AuthMethod': 'RPS',
          'SiteName': 'user.auth.xboxlive.com',
          'RpsTicket': 'd=$accessToken'
        },
        'RelyingParty': 'http://auth.xboxlive.com',
        'TokenType': 'JWT'
      }),
    );

    return response.data;
  }

  static Future<Response> _authorizationXSTS(
      String xblToken, String userHash) async {
    //Authenticate with XSTS

    Response response = await _httpClient.post(
        'https://xsts.auth.xboxlive.com/xsts/authorize',
        data: json.encode({
          'Properties': {
            'SandboxId': 'RETAIL',
            'UserTokens': [xblToken]
          },
          'RelyingParty': 'rp://api.minecraftservices.com/',
          'TokenType': 'JWT'
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
        'https://api.minecraftservices.com/launcher/login',
        data: json.encode({
          'xtoken': 'XBL3.0 x=$userHash;$xstsToken',
          'platform': 'PC_LAUNCHER'
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
        'https://api.minecraftservices.com/entitlements/license?requestId=${const Uuid().v4()}',
        options: Options(headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json'
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
        'https://api.minecraftservices.com/minecraft/profile',
        options: Options(
            headers: {'Authorization': 'Bearer $mcAccessToken'},
            responseType: ResponseType.json));
    Map data = response.data;

    if (data['error'].toString() == 'NOT_FOUND') {
      final context = navigator.context;
      if (context.mounted) {
        await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: I18nText.errorInfoText(),
                  content:
                      I18nText('account.add.microsoft.error.xbox_game_pass'),
                  actions: const [OkClose()],
                ));
      }

      return data;
    } else {
      return data;
    }
  }
}
