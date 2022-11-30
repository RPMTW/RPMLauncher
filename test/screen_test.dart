import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:line_icons/line_icons.dart';
import 'package:oauth2/oauth2.dart';
import 'package:rpmlauncher/launcher/apis.dart';
import 'package:rpmlauncher/mod/mod_loader.dart';
import 'package:rpmlauncher/model/account/Account.dart';
import 'package:rpmlauncher/model/Game/instance.dart';
import 'package:rpmlauncher/model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/pages/curseforge_modpack_page.dart';
import 'package:rpmlauncher/screen/about.dart';
import 'package:rpmlauncher/screen/account.dart';
import 'package:rpmlauncher/screen/ftb_modpack.dart';
import 'package:rpmlauncher/screen/InstanceIndependentSetting.dart';
import 'package:rpmlauncher/screen/ms_oauth_login.dart';
import 'package:rpmlauncher/screen/MojangAccount.dart';
import 'package:rpmlauncher/screen/RecommendedModpackScreen.dart';
import 'package:rpmlauncher/screen/Settings.dart';
import 'package:rpmlauncher/screen/version_selection.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/widget/dialog/download_java.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';

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
    testWidgets('VersionSelection Screen (Client)',
        (WidgetTester tester) async {
      rpmHttpClientAdapter = <T>(RequestOptions requestOptions) {
        if (requestOptions.method == 'GET' &&
            requestOptions.uri.toString() ==
                '$mojangMetaAPI/version_manifest_v2.json') {
          return Future.value(Response(
              requestOptions: requestOptions,
              data: json.decode(TestData.versionManifest.getFileString()) as T,
              statusCode: 200));
        }
        return null;
      };

      await TestHelper.baseTestWidget(
          tester, const VersionSelection(side: MinecraftSide.client));
      expect(find.text('1.18.1'), findsOneWidget);

      Finder showSnapshot = find.byType(Checkbox).last;
      Finder showRelease = find.byType(Checkbox).first;

      await tester.tap(showRelease);
      await tester.tap(showSnapshot);
      await tester.pumpAndSettle();

      Finder snapshot = find.text('21w44a');

      await tester.dragUntilVisible(
          snapshot, find.byType(ListView), const Offset(0.0, -300));
      await tester.pumpAndSettle();

      expect(find.text('1.18.1'), findsNothing);

      expect(snapshot, findsOneWidget);

      Finder modloader = find.byType(DropdownButton<String>);

      await tester.tap(modloader);
      await tester.pumpAndSettle();

      expect(find.text(ModLoader.forge.i18nString), findsWidgets);
      expect(find.text(ModLoader.fabric.i18nString), findsWidgets);
      expect(find.text(ModLoader.vanilla.i18nString), findsWidgets);
    });
    testWidgets('VersionSelection Screen (Server)',
        (WidgetTester tester) async {
      await TestHelper.baseTestWidget(
          tester, const VersionSelection(side: MinecraftSide.server),
          async: true);
      expect(find.text('1.18.1'), findsOneWidget);

      Finder modloader = find.byType(DropdownButton<String>);

      await tester.tap(modloader);
      await tester.pumpAndSettle();

      expect(find.text(ModLoader.forge.i18nString), findsNothing);
      expect(find.text(ModLoader.fabric.i18nString), findsWidgets);
      expect(find.text(ModLoader.paper.i18nString), findsWidgets);
      expect(find.text(ModLoader.vanilla.i18nString), findsWidgets);
    });
    testWidgets('CurseForge ModPack Screen', (WidgetTester tester) async {
      rpmHttpClientAdapter = <T>(RequestOptions requestOptions) {
        if (requestOptions.uri.toString() ==
                'https://api.rpmtw.com:2096/curseforge/?path=v1/mods/search?gameId=432%26classId=4471%26searchFilter=%26sortField=2%26sortOrder=d%E2%80%A6' &&
            requestOptions.method == 'GET') {
          return Future.value(Response(
              requestOptions: requestOptions,
              data: (json.decode(TestData.curseforgeModpack.getFileString()))
                  as T,
              statusCode: 200));
        }
        // else if (requestOptions.uri.toString() ==
        //         '$curseForgeModAPI/minecraft/version' &&
        //     requestOptions.method == 'GET') {
        //   return Future.value(Response(
        //       requestOptions: requestOptions,
        //       data: (json.decode(TestData.curseforgeVersion.getFileString()))
        //           as T,
        //       statusCode: 200));
        // }
        return null;
      };

      await TestHelper.baseTestWidget(tester, const CurseForgeModpackPage(),
          async: true);

      final Finder modPack = find.text('RLCraft');

      await tester.dragUntilVisible(
        modPack,
        find.byType(SingleChildScrollView),
        const Offset(0, 50),
      );

      expect(modPack, findsOneWidget);

      await tester.tap(modPack);
      await tester.pumpAndSettle();

      expect(
          find.text(
              'A modpack specially designed to bring an incredibly hardcore and semi-realism challenge revolving around survival, RPG elements, and adventure-like exploration.'),
          findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      final Finder installButton = find.text(I18n.format('gui.install'));
      expect(installButton, findsWidgets);
      await tester.tap(installButton.first);
      await tester.pumpAndSettle(
          const Duration(milliseconds: 100), EnginePhase.build);

      // TODO: Install ModPack
    }, skip: true);
    testWidgets('FTB ModPack Screen', (WidgetTester tester) async {
      rpmHttpClientAdapter = <T>(RequestOptions requestOptions) {
        if (requestOptions.uri.toString() == '$ftbModPackAPI/tag/popular/100' &&
            requestOptions.method == 'GET') {
          return Future.value(Response(
              requestOptions: requestOptions,
              data: (json.decode(TestData.ftbTags.getFileString())) as T,
              statusCode: 200));
        } else if (requestOptions.uri.toString() ==
                '$ftbModPackAPI/modpack/popular/installs/FTB/all' &&
            requestOptions.method == 'GET') {
          return Future.value(Response(
              requestOptions: requestOptions,
              data: (json.decode(TestData.ftbModpack.getFileString())) as T,
              statusCode: 200));
        } else if (requestOptions.uri.toString() ==
                '$ftbModPackAPI/modpack/35' &&
            requestOptions.method == 'GET') {
          return Future.value(Response(
              requestOptions: requestOptions,
              data: (json.decode(TestData.ftbModpack35.getFileString())) as T,
              statusCode: 200));
        }
        return null;
      };

      await TestHelper.baseTestWidget(tester, FTBModPack(), async: true);

      expect(find.text('FTB Revelation'), findsOneWidget);
      expect(
          find.text(
              'Revelation is a general all-purpose modpack with optimal FPS, server performance and stability.'),
          findsOneWidget);
    });

    testWidgets('Add Vanilla 1.17.1 Instance', (WidgetTester tester) async {
      await TestHelper.baseTestWidget(
          tester, const VersionSelection(side: MinecraftSide.client),
          async: true);

      final Finder versionText = find.text('1.17.1');

      await tester.tap(versionText);

      await tester.pumpAndSettle();

      final Finder confirm = find.text(I18n.format('gui.confirm'));
      expect(confirm, findsOneWidget);
      expect(find.text(I18n.format('gui.cancel')), findsOneWidget);

      await tester.tap(confirm);

      // TODO: Add Vanilla 1.17.1 Instance

      // await TestUttily.pumpAndSettle(tester);
    }, skip: true);
    testWidgets('Download Java Dialog', (WidgetTester tester) async {
      await TestHelper.baseTestWidget(
          tester, const DownloadJava(javaVersions: [8]),
          async: true);

      final Finder autoInstall =
          find.text(I18n.format('launcher.java.install.auto'));

      await tester.tap(autoInstall);
      await tester.pumpAndSettle();

      expect(find.text('0.00%'), findsOneWidget);

      await tester.runAsync(() async {
        await Future.delayed(const Duration(seconds: 3));
      });

      await tester.pump();

      expect(find.text('0.00%').evaluate().length, 0);

      expect(find.text(I18n.format('launcher.java.install.auto.download.done')),
          findsOneWidget);

      if (find
          .text(I18n.format('launcher.java.install.auto.download.done'))
          .evaluate()
          .isNotEmpty) {
        final Finder close = find.byType(OkClose);
        await tester.tap(close);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Add Mojang Account', (WidgetTester tester) async {
      String mockToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiU2lvbmdTbmciLCJ0ZXh0IjoiSGVsbG8gUlBNVFcgV29ybGQifQ.Q7VjOWCjl_FI9W4kPlSaYLAUaUqCgfMe5YjnQEtBdTU';
      String mockUUID = 'a9b8f8f7-e8e7-4f6d-b8c6-b8c8f8f7e8e7';
      String mockEmail = 'RPMTW@email.example';

      rpmHttpClientAdapter = <T>(RequestOptions requestOptions) {
        if (requestOptions.uri.toString() == '$mojangAuthAPI/authenticate' &&
            requestOptions.method == 'POST') {
          return Future.value(Response<T>(
              requestOptions: requestOptions,
              data: {
                'user': {
                  'username': mockEmail,
                  'properties': [
                    {'name': 'preferredLanguage', 'value': 'en-us'},
                    {'name': 'registrationCountry', 'value': 'country'}
                  ],
                  'id': mockUUID
                },
                'accessToken': mockToken,
                'availableProfiles': [
                  {'name': 'RPMTW', 'id': mockUUID}
                ],
                'selectedProfile': {'name': 'RPMTW', 'id': mockUUID}
              } as T,
              statusCode: 200));
        }
        return null;
      };

      await TestHelper.baseTestWidget(tester, const MojangAccount());
      expect(find.text(I18n.format('account.mojang.title')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('mojang_email')), 'RPMTW');
      await tester.enterText(
          find.byKey(const Key('mojang_passwd')), 'hello_rpmtw_world');

      await tester.pumpAndSettle();

      /// 顯示密碼

      Finder showPasswd = find.text(I18n.format('account.passwd.show'));

      expect(showPasswd, findsOneWidget);
      await tester.tap(showPasswd);
      await tester.pumpAndSettle();

      expect(showPasswd, findsNothing);
      expect(find.text(I18n.format('account.passwd.hide')), findsOneWidget);
      expect(find.text('hello_rpmtw_world'), findsOneWidget);

      final Finder loginButton = find.text(I18n.format('gui.login'));

      await tester.dragUntilVisible(
        loginButton,
        find.byType(SingleChildScrollView),
        const Offset(0, 50),
      );

      await tester.pumpAndSettle();

      await tester.tap(loginButton);

      await tester.pumpAndSettle();

      /// 確認 Mojang 帳號登入成功
      expect(find.text(I18n.format('account.add.successful')), findsOneWidget);
      expect(AccountStorage().getIndex() != -1, true);
      expect(
          AccountStorage().getByUUID('a9b8f8f7-e8e7-4f6d-b8c6-b8c8f8f7e8e7'),
          Account(AccountType.mojang, mockToken, mockUUID, 'RPMTW',
              email: mockEmail));
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
    testWidgets('Recommended Modpack Screen', (WidgetTester tester) async {
      await TestHelper.baseTestWidget(
          tester, const Material(child: RecommendedModpackScreen()),
          async: true);

      expect(find.text(I18n.format('version.recommended_modpack.title')),
          findsOneWidget);

      Finder linkButton =
          find.text(I18n.format('version.recommended_modpack.link'));

      Finder installButton = find.text(I18n.format('gui.install'));

      await tester.tap(linkButton.first);
      await tester.pumpAndSettle();

      rpmHttpClientAdapter = <T>(RequestOptions requestOptions) {
        if (requestOptions.method == 'GET' &&
            requestOptions.uri.toString() ==
                '$mojangMetaAPI/version_manifest_v2.json') {
          return Future.value(Response(
              requestOptions: requestOptions,
              data: json.decode(TestData.versionManifest.getFileString()) as T,
              statusCode: 200));
        }
        return null;
      };

      await tester.tap(installButton.first);
      await tester.pumpAndSettle();
    });
    testWidgets(
      'Instance Independent Setting',
      (WidgetTester tester) async {
        InstanceConfig config = InstanceConfig.unknown();

        await TestHelper.baseTestWidget(
            tester,
            Material(
                child: InstanceIndependentSetting(instanceConfig: config)));

        expect(find.text(I18n.format('gui.default')), findsOneWidget);
      },
    );
  });
}
