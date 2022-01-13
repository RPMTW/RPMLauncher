import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Launcher/Arguments.dart';
import 'package:rpmlauncher/Model/Game/FabricInstallerVersion.dart';
import 'package:rpmlauncher/Model/Game/Libraries.dart';
import '../TestUttitily.dart';

void main() async {
  setUpAll(() => TestUttily.init());

  group('Game -', () {
    test("Game library serialization and deserialization ", () {
      Map meta = json.decode(TestData.minecraftMeta.getFileString());
      Libraries libraries = Libraries.fromList(meta['libraries']);

      expect(
          libraries.any((lib) => lib.name == "com.google.code.gson:gson:2.8.8"),
          true);

      Library library = libraries
          .firstWhere((lib) => lib.name == "com.google.code.gson:gson:2.8.8");

      expect(library.name, "com.google.code.gson:gson:2.8.8");
      expect(library.need, true);
      expect(library.rules, null);

      log(
        libraries.getLibrariesLauncherArgs(File("1.18-pre6.jar")),
      );

      // String args = r"1.18-pre6.jar";

      /*
      1.18-pre6.jar:${Data_Home}/libraries/com/mojang/blocklist/1.0.6/blocklist-1.0.6.jar:${Data_Home}/libraries/com/mojang/patchy/2.1.6/patchy-2.1.6.jar:${Data_Home}/libraries/com/github/oshi/oshi-core/5.8.2/oshi-core-5.8.2.jar:${Data_Home}/libraries/net/java/dev/jna/jna/5.9.0/jna-5.9.0.jar:${Data_Home}/libraries/net/java/dev/jna/jna-platform/5.9.0/jna-platform-5.9.0.jar:${Data_Home}/libraries/org/slf4j/slf4j-api/1.8.0-beta4/slf4j-api-1.8.0-beta4.jar:${Data_Home}/libraries/org/apache/logging/log4j/log4j-slf4j18-impl/2.14.1/log4j-slf4j18-impl-2.14.1.jar:${Data_Home}/libraries/com/ibm/icu/icu4j/69.1/icu4j-69.1.jar:${Data_Home}/libraries/com/mojang/javabridge/1.2.24/javabridge-1.2.24.jar:${Data_Home}/libraries/net/sf/jopt-simple/jopt-simple/5.0.4/jopt-simple-5.0.4.jar:${Data_Home}/libraries/io/netty/netty-all/4.1.68.Final/netty-all-4.1.68.Final.jar:${Data_Home}/libraries/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar:${Data_Home}/libraries/com/google/guava/guava/31.0.1-jre/guava-31.0.1-jre.jar:${Data_Home}/libraries/org/apache/commons/commons-lang3/3.12.0/commons-lang3-3.12.0.jar:${Data_Home}/libraries/commons-io/commons-io/2.11.0/commons-io-2.11.0.jar:${Data_Home}/libraries/commons-codec/commons-codec/1.15/commons-codec-1.15.jar:${Data_Home}/libraries/com/mojang/brigadier/1.0.18/brigadier-1.0.18.jar:${Data_Home}/libraries/com/mojang/datafixerupper/4.0.26/datafixerupper-4.0.26.jar:${Data_Home}/libraries/com/google/code/gson/gson/2.8.8/gson-2.8.8.jar:${Data_Home}/libraries/com/mojang/authlib/3.2.38/authlib-3.2.38.jar:${Data_Home}/libraries/org/apache/commons/commons-compress/1.21/commons-compress-1.21.jar:${Data_Home}/libraries/org/apache/httpcomponents/httpclient/4.5.13/httpclient-4.5.13.jar:${Data_Home}/libraries/commons-logging/commons-logging/1.2/commons-logging-1.2.jar:${Data_Home}/libraries/org/apache/httpcomponents/httpcore/4.4.14/httpcore-4.4.14.jar:${Data_Home}/libraries/it/unimi/dsi/fastutil/8.5.6/fastutil-8.5.6.jar:${Data_Home}/libraries/org/apache/logging/log4j/log4j-api/2.14.1/log4j-api-2.14.1.jar:${Data_Home}/libraries/org/apache/logging/log4j/log4j-core/2.14.1/log4j-core-2.14.1.jar:${Data_Home}/libraries/org/lwjgl/lwjgl/3.2.2/lwjgl-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-jemalloc/3.2.2/lwjgl-jemalloc-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-openal/3.2.2/lwjgl-openal-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-opengl/3.2.2/lwjgl-opengl-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-glfw/3.2.2/lwjgl-glfw-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-stb/3.2.2/lwjgl-stb-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-tinyfd/3.2.2/lwjgl-tinyfd-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl/3.2.2/lwjgl-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-jemalloc/3.2.2/lwjgl-jemalloc-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-openal/3.2.2/lwjgl-openal-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-opengl/3.2.2/lwjgl-opengl-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-glfw/3.2.2/lwjgl-glfw-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-tinyfd/3.2.2/lwjgl-tinyfd-3.2.2.jar:${Data_Home}/libraries/org/lwjgl/lwjgl-stb/3.2.2/lwjgl-stb-3.2.2.jar:${Data_Home}/libraries/com/mojang/text2speech/1.11.3/text2speech-1.11.3.jar:${Data_Home}/libraries/com/mojang/text2speech/1.11.3/text2speech-1.11.3.jar

      .replaceAll(r"${Data_Home}", dataHome.absolute.path)
      .replaceAll(":", Uttily.getLibrarySeparator())
      */

      // expect(libraries.getLibrariesLauncherArgs(File("1.18-pre6.jar")), args);

      log("Library Files: ${libraries.getLibrariesFiles()}");
    });
    test("Forge 1.12.2 arguments parse", () {
      Map args = json.decode(TestData.forge112Args.getFileString());

      Arguments.getForge(args, {}, Version(1, 12, 2));
    });
    test("Fabric 1.17.1 arguments parse", () {
      Map args = json.decode(TestData.fabric117Args.getFileString());

      List<String> parsedArgs = Arguments.getVanilla(
          args, {r"${auth_player_name}": "RPMTW"}, Version(1, 17, 1));

      expect(parsedArgs.contains('RPMTW'), true);
    });
    test('Fabric Installer Version', () {
      FabricInstallerVersions versions = FabricInstallerVersions.fromJson(
          TestData.fabricInstallerVersion.getFileString());

      expect(
          versions.first,
          FabricInstallerVersion(
              url:
                  "https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.10.2/fabric-installer-0.10.2.jar",
              maven: "net.fabricmc:fabric-installer:0.10.2",
              version: "0.10.2",
              stable: true));

      expect(versions.firstWhere((e) => e.stable).version, "0.10.2");
    });
  });
}
