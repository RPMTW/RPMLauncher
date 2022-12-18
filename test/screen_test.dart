import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:line_icons/line_icons.dart';
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/ui/screen/about.dart';
import 'package:rpmlauncher/ui/screen/account.dart';
import 'package:rpmlauncher/ui/screen/ms_oauth_login.dart';
import 'package:rpmlauncher/ui/screen/settings.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/util/launcher_info.dart';

import 'script/test_helper.dart';

void main() {
  setUpAll(() => TestHelper.init());

  group('RPMLauncher Screen Test -', () {
    testWidgets('Settings Screen', (WidgetTester tester) async {
      await TestHelper.baseTestWidget(tester, SettingScreen());

      expect(find.text(I18n.format('settings.title')), findsOneWidget);

      final Finder appearancePage =
          find.text(I18n.format('settings.appearance.title'));

      await tester.tap(appearancePage);
      await tester.pumpAndSettle();

      expect(
          find.text(I18n.format('settings.appearance.theme')), findsOneWidget);
    });
    testWidgets('About Screen', (WidgetTester tester) async {
      await TestHelper.baseTestWidget(tester, AboutScreen());

      final Finder showLicense = find.byIcon(Icons.book_outlined);

      await tester.tap(showLicense);
      await tester.pumpAndSettle();

      expect(find.text(LauncherInfo.getUpperCaseName()), findsOneWidget);
      expect(find.text(LauncherInfo.getFullVersion()), findsOneWidget);
      expect(find.text('Powered by Flutter'), findsOneWidget);

      final Finder back = find.byType(BackButton);

      await tester.tap(back);
      await tester.pumpAndSettle();

      final Finder discord = find.byIcon(LineIcons.discord);
      final Finder github = find.byIcon(LineIcons.github);
      final Finder rpmtwWebsite = find.byIcon(LineIcons.home);

      await tester.tap(discord);
      await tester.tap(github);
      await tester.tap(rpmtwWebsite);

      await tester.pumpAndSettle();
    });
    testWidgets('Account Screen', (WidgetTester tester) async {
      await TestHelper.baseTestWidget(tester, AccountScreen(), async: true);
      await tester.pumpAndSettle();

      final Finder mojangLogin =
          find.text(I18n.format('account.add.mojang.title'));

      expect(mojangLogin, findsOneWidget);

      await tester.tap(mojangLogin);
      await tester.pumpAndSettle();

      expect(find.text(I18n.format('account.mojang.title')), findsOneWidget);
    });

    testWidgets('Add Microsoft Account', (WidgetTester tester) async {
      String mockToken =
          'eyJhbGciOiJIUzI1NiIsImxhbmciOiJkYXJ0IiwidHlwIjoiSldUIn0.eyJzdWIiOiIxMjM0NTY3ODkwIiwidGVzdCI6IlJQTVRXIn0.Nd1lXCNoXIqQivebe5Sj4Y7LEt0oSTkbOYIThIZl_II';
      String mockRefreshToken =
          'M.R3_BAY.-CS1snzEaQsj1AUl6sp1!4UIxuAJEXwSc!BCsAsjahoWGxRgYoCad!ltICMc80mBT33tbHmBpioDPc722coOnNF3nItthH8CL4uSbHaRv4!nzYDmZdtN9QsLAPs24mSsxn*EISkg4vWziNi9GhmXFZ6qqZrwq8pFbCn3CxGPc9QgqdyAh6T9Smkwxxw26duFRKajIBDR86B6Y5jRjE8EiLhCbq9IFZUo9cniQQd2Su20*mRIRPya8pUvrIzADvDIJy1!0Cnff!MVLB0vLvdngKRLErHPmaiMldYEtCTr1*zeg';

      String mockUUID = '896a07c6-7a99-4e4d-9c53-608cfa4fd581';

      Credentials mockCredentials = Credentials(mockToken,
          refreshToken: mockRefreshToken,
          tokenEndpoint: Uri.parse('https://login.live.com/oauth20_token.srf'),
          scopes: ['XboxLive.signin'],
          expiration: DateTime.parse('2021-12-04'));

      microsoftOauthMock = () => Future.value(Client(mockCredentials));

      rpmHttpClientAdapter = <T>(RequestOptions requestOptions) {
        if (requestOptions.uri.toString() ==
                'https://user.auth.xboxlive.com/user/authenticate' &&
            requestOptions.method == 'POST') {
          return Future.value(Response(
              requestOptions: requestOptions,
              data: {
                'IssueInstant': '2021-12-04T19:52:08.4463796Z',
                'NotAfter': '2032-1-1T19:52:08.4463796Z',
                'Token': 'xbl_token',
                'DisplayClaims': {
                  'xui': [
                    {'uhs': 'xbl_user_hash'}
                  ]
                }
              } as T,
              statusCode: 200));
        } else if (requestOptions.uri.toString() ==
                'https://xsts.auth.xboxlive.com/xsts/authorize' &&
            requestOptions.method == 'POST') {
          return Future.value(Response(
              requestOptions: requestOptions,
              data: {
                'IssueInstant': '2021-12-04T19:52:08.4463796Z',
                'NotAfter': '2032-1-1T19:52:08.4463796Z',
                'Token': 'xsts_token',
                'DisplayClaims': {
                  'xui': [
                    {'uhs': 'xsts_user_hash'}
                  ]
                }
              } as T,
              statusCode: 200));
        } else if (requestOptions.uri.toString() ==
                'https://api.minecraftservices.com/launcher/login' &&
            requestOptions.method == 'POST') {
          return Future.value(Response(
              requestOptions: requestOptions,
              data: {
                'username': mockUUID,
                'roles': [],
                'access_token': mockToken,
                'token_type': 'Bearer',
                'expires_in': 86400
              } as T,
              statusCode: 200));
        } else if (requestOptions.uri.toString().startsWith(
                'https://api.minecraftservices.com/entitlements/license') &&
            requestOptions.method == 'GET') {
          return Future.value(Response(
              requestOptions: requestOptions,
              data: {
                'items': [
                  {'name': 'product_minecraft_bedrock', 'source': 'PURCHASE'},
                  {'name': 'game_minecraft_bedrock', 'source': 'PURCHASE'},
                  {'name': 'product_minecraft', 'source': 'MC_PURCHASE'},
                  {'name': 'game_minecraft', 'source': 'MC_PURCHASE'}
                ],
                'signature':
                    'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IjEiLCJ4NXQiOiJJVXRXd1l0clNfSXpJS0piaTZzNGtWaF9FNXMifQ.ewogICJlbnRpdGxlbWVudHMiIDogWyB7CiAgICAibmFtZSIgOiAicHJvZHVjdF9taW5lY3JhZnRfYmVkcm9jayIsCiAgICAic291cmNlIiA6ICJQVVJDSEFTRSIKICB9LCB7CiAgICAibmFtZSIgOiAiZ2FtZV9taW5lY3JhZnRfYmVkcm9jayIsCiAgICAic291cmNlIiA6ICJQVVJDSEFTRSIKICB9LCB7CiAgICAibmFtZSIgOiAicHJvZHVjdF9taW5lY3JhZnQiLAogICAgInNvdXJjZSIgOiAiTUNfUFVSQ0hBU0UiCiAgfSwgewogICAgIm5hbWUiIDogImdhbWVfbWluZWNyYWZ0IiwKICAgICJzb3VyY2UiIDogIk1DX1BVUkNIQVNFIgogIH0gXSwKICAic2lnbmVySWQiIDogIjI1MzU0NTczMDk1Nzg4NjQiLAogICJuYmYiIDogMTYzODU4NjQ1MywKICAicmVxdWVzdElkIiA6ICJjOGEwOWUyNS05ZjI1LTQwYmMtYTNiZi0zMzdkY2U4MGQ1NDIiLAogICJyaWRjciIgOiAiZGZjMDUwMTVhZTIwM2IyNiIsCiAgImV4cCIgOiAxNjM4NzU5NDMzLAogICJpYXQiIDogMTYzODU4NjYzMywKICAicGxhdGZvcm0iIDogIlBDX0xBVU5DSEVSIgp9.EA51R3SsPpcN9GLwX_T1g7hJ0Z0vcvUSOZb9c-4vBliY3EfvgH7y3hcUzPLu40kazkmE2hsRuG-TmgWYIdSqmprZZd390r4tCDtmo4wXqGrZ1OUDK3wdQLSBU0F2LLc2wqYTj0e1aehlYhHe3FfCSWP90gsmm__IoBgkKaMJkDT7R_7dqQCvwARvzwuN9XoFzakKuKRb1Lz7vMnstWCXqtwCeaZhOUs12A0mZvce4721Www3OVneRURf35wADV4cGNCzO91AqVzHjshLk0HehPMjzaO-gRAw_TiDxAQm2Md48Cf08OlNMdHzppMt04vg4FZh_HlqzIFhgi2L2Drq4uTHS_8SS4y1Zou10PPser0AmX5Uz3V_OaipRVgd4BQ0xnx4Q4DZkgVX0gh-FbBQ4X307-RGjl4AvnCG6yyx6tsctKeIrsmPSwcJYzGWxAk3A6VDgrXnvtMkw9bDNHrVzgwAl54BhvdxFRJl5knal9rc0-WVesf3wUc-h2lKO7vLz_e9lBhwf_4zFirkvrwjr_67mMp-a498GnvCuznTf633C4ygN-RTvaX51tgnR6PUwjdMlsqqTk4VsFAr3Ljl-rc526-EEQ6GPRk6tXZyUSfYMiL98J9Btc9rYNbDeJlNM2rM3Zd_okqyD1_xtPYjjuvwogxxM7t69oi9hM_v8Wc',
                'keyId': '1',
                'requestId': 'c8a09e25-9f25-40bc-a3bf-337dce80d542'
              } as T,
              statusCode: 200));
        } else if (requestOptions.uri.toString() ==
                'https://api.minecraftservices.com/minecraft/profile' &&
            requestOptions.method == 'GET') {
          return Future.value(Response(
              requestOptions: requestOptions,
              data: {
                'id': mockUUID,
                'name': 'RPMTW',
                'skins': [
                  {
                    'id': '6a6e65e5-76dd-4c3c-a625-162924514568',
                    'state': 'ACTIVE',
                    'url':
                        'http://textures.minecraft.net/texture/1a4af718455d4aab528e7a61f86fa25e6a369d1768dcb13f7df319a713eb810b',
                    'variant': 'CLASSIC',
                    'alias': 'STEVE'
                  }
                ],
                'capes': []
              } as T,
              statusCode: 200));
        }
        return null;
      };

      await TestHelper.baseTestWidget(tester, MSLoginWidget());
      await tester.pumpAndSettle();

      expect(find.text(I18n.format('account.add.microsoft.state.title')),
          findsOneWidget);
      expect(find.text(I18n.format('account.add.successful')), findsOneWidget);

      // TODO:處理各種 Microsoft 帳號登入例外錯誤
    });
  });
}
