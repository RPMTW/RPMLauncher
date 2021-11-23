import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpmlauncher/Model/Game/Libraries.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import '../TestUttily.dart';

void main() async {
  setUpAll(() => TestUttily.init());

  group('Game -', () {
    test("Game library serialization and deserialization ", () {
      Map meta = json.decode(TestData.minecraftMeta.getFileString());
      Libraries libraries = Libraries.fromList(meta['libraries']);

      expect(
          libraries.any((lib) => lib.name == "com.google.code.gson:gson:2.8.8"),
          true);

      log(
        libraries.getLibrariesLauncherArgs(File("1.18-pre6.jar")),
      );

      String args =
          r"1.18-pre6.jar:/home/siongsng/RPMLauncher/data/libraries/com/mojang/blocklist/1.0.6/blocklist-1.0.6.jar:/home/siongsng/RPMLauncher/data/libraries/com/mojang/patchy/2.1.6/patchy-2.1.6.jar:/home/siongsng/RPMLauncher/data/libraries/com/github/oshi/oshi-core/5.8.2/oshi-core-5.8.2.jar:/home/siongsng/RPMLauncher/data/libraries/net/java/dev/jna/jna/5.9.0/jna-5.9.0.jar:/home/siongsng/RPMLauncher/data/libraries/net/java/dev/jna/jna-platform/5.9.0/jna-platform-5.9.0.jar:/home/siongsng/RPMLauncher/data/libraries/org/slf4j/slf4j-api/1.8.0-beta4/slf4j-api-1.8.0-beta4.jar:/home/siongsng/RPMLauncher/data/libraries/org/apache/logging/log4j/log4j-slf4j18-impl/2.14.1/log4j-slf4j18-impl-2.14.1.jar:/home/siongsng/RPMLauncher/data/libraries/com/ibm/icu/icu4j/69.1/icu4j-69.1.jar:/home/siongsng/RPMLauncher/data/libraries/com/mojang/javabridge/1.2.24/javabridge-1.2.24.jar:/home/siongsng/RPMLauncher/data/libraries/net/sf/jopt-simple/jopt-simple/5.0.4/jopt-simple-5.0.4.jar:/home/siongsng/RPMLauncher/data/libraries/io/netty/netty-all/4.1.68.Final/netty-all-4.1.68.Final.jar:/home/siongsng/RPMLauncher/data/libraries/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar:/home/siongsng/RPMLauncher/data/libraries/com/google/guava/guava/31.0.1-jre/guava-31.0.1-jre.jar:/home/siongsng/RPMLauncher/data/libraries/org/apache/commons/commons-lang3/3.12.0/commons-lang3-3.12.0.jar:/home/siongsng/RPMLauncher/data/libraries/commons-io/commons-io/2.11.0/commons-io-2.11.0.jar:/home/siongsng/RPMLauncher/data/libraries/commons-codec/commons-codec/1.15/commons-codec-1.15.jar:/home/siongsng/RPMLauncher/data/libraries/com/mojang/brigadier/1.0.18/brigadier-1.0.18.jar:/home/siongsng/RPMLauncher/data/libraries/com/mojang/datafixerupper/4.0.26/datafixerupper-4.0.26.jar:/home/siongsng/RPMLauncher/data/libraries/com/google/code/gson/gson/2.8.8/gson-2.8.8.jar:/home/siongsng/RPMLauncher/data/libraries/org/apache/commons/commons-compress/1.21/commons-compress-1.21.jar:/home/siongsng/RPMLauncher/data/libraries/org/apache/httpcomponents/httpclient/4.5.13/httpclient-4.5.13.jar:/home/siongsng/RPMLauncher/data/libraries/commons-logging/commons-logging/1.2/commons-logging-1.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/apache/httpcomponents/httpcore/4.4.14/httpcore-4.4.14.jar:/home/siongsng/RPMLauncher/data/libraries/it/unimi/dsi/fastutil/8.5.6/fastutil-8.5.6.jar:/home/siongsng/RPMLauncher/data/libraries/org/apache/logging/log4j/log4j-api/2.14.1/log4j-api-2.14.1.jar:/home/siongsng/RPMLauncher/data/libraries/org/apache/logging/log4j/log4j-core/2.14.1/log4j-core-2.14.1.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl/3.2.2/lwjgl-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-jemalloc/3.2.2/lwjgl-jemalloc-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-openal/3.2.2/lwjgl-openal-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-opengl/3.2.2/lwjgl-opengl-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-glfw/3.2.2/lwjgl-glfw-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-stb/3.2.2/lwjgl-stb-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-tinyfd/3.2.2/lwjgl-tinyfd-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl/3.2.2/lwjgl-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-jemalloc/3.2.2/lwjgl-jemalloc-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-openal/3.2.2/lwjgl-openal-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-opengl/3.2.2/lwjgl-opengl-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-glfw/3.2.2/lwjgl-glfw-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-tinyfd/3.2.2/lwjgl-tinyfd-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/org/lwjgl/lwjgl-stb/3.2.2/lwjgl-stb-3.2.2.jar:/home/siongsng/RPMLauncher/data/libraries/com/mojang/text2speech/1.11.3/text2speech-1.11.3.jar:/home/siongsng/RPMLauncher/data/libraries/com/mojang/text2speech/1.11.3/text2speech-1.11.3.jar";

      expect(libraries.getLibrariesLauncherArgs(File("1.18-pre6.jar")),
          args.replaceAll(":", Uttily.getLibrarySeparator()));

      log("Library Files: ${libraries.getLibrariesFiles()}");
    });
  });
}
