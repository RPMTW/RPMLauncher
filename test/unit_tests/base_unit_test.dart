import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/function/analytics.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/model/Game/jvm_args.dart';
import 'package:rpmlauncher/model/IO/Properties.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/logger.dart';
import 'package:rpmlauncher/util/updater.dart';
import 'package:rpmlauncher_plugin/rpmlauncher_plugin.dart';

import '../script/test_helper.dart';

void main() async {
  setUpAll(() => TestHelper.init());

  const MethodChannel channel = MethodChannel('rpmlauncher_plugin');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getTotalPhysicalMemory') {
        return 8589934592.00; // 8GB
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  group('RPMLauncher Unit Test -', () {
    test(
      'i18n',
      () async {
        I18n.getSystemLanguage();
        log(I18n.format('init.quick_setup.content'));
      },
    );
    test('Launcher info', () async {
      log("Launcher Version: ${LauncherInfo.version}");
      log("Launcher Version Type (i18n): ${Updater.toI18nString(LauncherInfo.getVersionType())}");
      log("Launcher Executing File: ${LauncherInfo.getExecutingFile()}");
      log("Launcher DataHome: $dataHome");
      log("PhysicalMemory: ${await RPMLauncherPlugin.getTotalPhysicalMemory()} MB");
    });
    testWidgets('Check dev updater', (WidgetTester tester) async {
      LauncherInfo.isDebugMode = false;
      late VersionInfo dev;
      await tester.runAsync(() async {
        dev = await Updater.checkForUpdate(VersionTypes.dev);
      });

      await TestHelper.baseTestWidget(tester, Container());

      if (dev.needUpdate) {
        log("Dev channel need update");
        await Updater.download(dev);
      } else {
        log("Dev channel not need update");
      }
    });
    test('Check debug updater', () async {
      /// 如果更新通道是 debug ，將不會收到更新資訊，因此返回 false
      expect(
          (await Updater.checkForUpdate(VersionTypes.debug)).needUpdate, false);
    });
    // test('Check stable updater', () async {
    //   LauncherInfo.isDebugMode = false;
    //   bool Stable =
    //       (await Updater.checkForUpdate(VersionTypes.stable)).needUpdate;
    //   print("Stable channel ${Stable ? "need update" : "not need update"}");
    // });
    test('log test', () {
      Logger.current.info('Hello World');
      Logger.current.error(ErrorType.unknown, "Test Unknown Error",
          stackTrace: StackTrace.current);
    });
    test('Google Analytics', () async {
      Analytics ga = Analytics();
      await ga.ping();
    });
  });
  test("Properties parsing", () {
    String propertiesText = '''
    # 測試註解
    name=RPMTW
    version=1.0.0
    # 作者
    author=SiongSng,The RPMTW Team
    language=zh_TW
    ''';

    Properties properties = Properties.decode(propertiesText);

    expect(properties['name'], "RPMTW");
    expect(properties['version'], "1.0.0");
    expect(properties['author'], "SiongSng,The RPMTW Team");
    expect(properties['language'], "zh_TW");
    expect(properties.comments, [" 測試註解", " 作者"]);
    expect(properties.keys, ["name", "version", "author", "language"]);

    String propertiesText2 =
        "name=RPMTW\nversion=1.0.0\nauthor=SiongSng,The RPMTW Team\nlanguage=zh_TW";

    expect(Properties.encode(properties), propertiesText2);

    String rpmtw = properties.remove('name')!;
    expect(rpmtw, "RPMTW");
    expect(properties.length, 3);
    properties.clear();
    expect(properties.length, 0);
  });
  test("JVM args parsing", () {
    String jvmArgs =
        "-XX:+AggressiveOpts -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSConcurrentMTEnabled -XX:ParallelGCThreads=8 -Dsun.rmi.dgc.server.gcInterval=1800000 -XX:+UnlockExperimentalVMOptions -XX:+ExplicitGCInvokesConcurrent -XX:MaxGCPauseMillis=50 -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -Dfml.ignorePatchDiscrepancies=true -Dfml.ignoreInvalidMinecraftCertificates=true -XX:-OmitStackTraceInFastThrow -XX:+OptimizeStringConcat -XX:+UseAdaptiveGCBoundary -XX:NewRatio=3 -Dfml.readTimeout=90 -XX:+UseFastAccessorMethods -XX:CMSInitiatingOccupancyFraction=75 -XX:+CMSScavengeBeforeRemark -XX:+UseCMSInitiatingOccupancyOnly";

    JvmArgs args = JvmArgs(args: jvmArgs);

    List<String> list = [
      "-XX:+AggressiveOpts",
      "-XX:+UseConcMarkSweepGC",
      "-XX:+UseParNewGC",
      "-XX:+CMSConcurrentMTEnabled",
      "-XX:ParallelGCThreads=8",
      "-Dsun.rmi.dgc.server.gcInterval=1800000",
      "-XX:+UnlockExperimentalVMOptions",
      "-XX:+ExplicitGCInvokesConcurrent",
      "-XX:MaxGCPauseMillis=50",
      "-XX:+AlwaysPreTouch",
      "-XX:+UseStringDeduplication",
      "-Dfml.ignorePatchDiscrepancies=true",
      "-Dfml.ignoreInvalidMinecraftCertificates=true",
      "-XX:-OmitStackTraceInFastThrow",
      "-XX:+OptimizeStringConcat",
      "-XX:+UseAdaptiveGCBoundary",
      "-XX:NewRatio=3",
      "-Dfml.readTimeout=90",
      "-XX:+UseFastAccessorMethods",
      "-XX:CMSInitiatingOccupancyFraction=75",
      "-XX:+CMSScavengeBeforeRemark",
      "-XX:+UseCMSInitiatingOccupancyOnly"
    ];

    expect(args.toList(), list);
    expect(JvmArgs.fromList(list).args, jvmArgs);
  });
  test("JVM args parsing", () {
    String jvmArgs =
        "-XX:+AggressiveOpts -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSConcurrentMTEnabled -XX:ParallelGCThreads=8 -Dsun.rmi.dgc.server.gcInterval=1800000 -XX:+UnlockExperimentalVMOptions -XX:+ExplicitGCInvokesConcurrent -XX:MaxGCPauseMillis=50 -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -Dfml.ignorePatchDiscrepancies=true -Dfml.ignoreInvalidMinecraftCertificates=true -XX:-OmitStackTraceInFastThrow -XX:+OptimizeStringConcat -XX:+UseAdaptiveGCBoundary -XX:NewRatio=3 -Dfml.readTimeout=90 -XX:+UseFastAccessorMethods -XX:CMSInitiatingOccupancyFraction=75 -XX:+CMSScavengeBeforeRemark -XX:+UseCMSInitiatingOccupancyOnly";

    JvmArgs args = JvmArgs(args: jvmArgs);

    List<String> list = [
      "-XX:+AggressiveOpts",
      "-XX:+UseConcMarkSweepGC",
      "-XX:+UseParNewGC",
      "-XX:+CMSConcurrentMTEnabled",
      "-XX:ParallelGCThreads=8",
      "-Dsun.rmi.dgc.server.gcInterval=1800000",
      "-XX:+UnlockExperimentalVMOptions",
      "-XX:+ExplicitGCInvokesConcurrent",
      "-XX:MaxGCPauseMillis=50",
      "-XX:+AlwaysPreTouch",
      "-XX:+UseStringDeduplication",
      "-Dfml.ignorePatchDiscrepancies=true",
      "-Dfml.ignoreInvalidMinecraftCertificates=true",
      "-XX:-OmitStackTraceInFastThrow",
      "-XX:+OptimizeStringConcat",
      "-XX:+UseAdaptiveGCBoundary",
      "-XX:NewRatio=3",
      "-Dfml.readTimeout=90",
      "-XX:+UseFastAccessorMethods",
      "-XX:CMSInitiatingOccupancyFraction=75",
      "-XX:+CMSScavengeBeforeRemark",
      "-XX:+UseCMSInitiatingOccupancyOnly"
    ];

    expect(args.toList(), list);
    expect(JvmArgs.fromList(list).args, jvmArgs);
  });
}
