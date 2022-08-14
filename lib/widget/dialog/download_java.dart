import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:rpmlauncher/model/IO/isolate_option.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmlauncher/util/Process.dart';
import 'package:rpmlauncher/util/config.dart';
import 'package:rpmlauncher/util/i18n.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/util/util.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';
import 'package:rpmlauncher/widget/settings/java_path.dart';
import 'package:rpmlauncher/util/data.dart';

class DownloadJava extends StatefulWidget {
  final List<int> javaVersions;
  final Function? onDownloaded;

  const DownloadJava({required this.javaVersions, this.onDownloaded});

  @override
  State<DownloadJava> createState() => _DownloadJavaState();
}

class _DownloadJavaState extends State<DownloadJava> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: I18nText(
        'gui.tips.info',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 25),
      ),
      content: I18nText(
        'launcher.java.install.not',
        args: {
          'java_version': widget.javaVersions.join(I18n.format('gui.separate'))
        },
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
        ),
      ),
      actions: [
        Center(
            child: TextButton(
                child: I18nText('launcher.java.install.auto',
                    style: const TextStyle(fontSize: 20, color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => Task(
                            javaVersions: widget.javaVersions,
                            onDownloaded: widget.onDownloaded,
                          ));
                })),
        const SizedBox(
          height: 10,
        ),
        Center(
            child: TextButton(
          child: I18nText('launcher.java.install.manual',
              style: const TextStyle(fontSize: 20, color: Colors.lightBlue)),
          onPressed: () {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: I18nText('launcher.java.install.manual'),
                      content: const JavaPathWidget(),
                      actions: [
                        OkClose(
                          onOk: () {
                            List<int> needVersions =
                                Util.javaCheck(widget.javaVersions);

                            if (needVersions.isNotEmpty) {
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: I18nText.errorInfoText(),
                                        content: I18nText(
                                            'launcher.java.install.manual.error'),
                                        actions: const [OkClose()],
                                      ));
                            } else {
                              Navigator.pop(context);
                              widget.onDownloaded?.call();
                            }
                          },
                        )
                      ],
                    ));
          },
        )),
      ],
    );
  }
}

class Task extends StatefulWidget {
  final List<int> javaVersions;
  final Function? onDownloaded;
  const Task({required this.javaVersions, this.onDownloaded});

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  late List<double> downloadJavaProgress;
  late List<bool> finishList;
  bool isExtractingArchive = false;

  double get downloadProgress {
    if (finishList.every((b) => b)) return 1;

    double p = 0.0;
    downloadJavaProgress.forEach((progress) {
      p += progress;
    });

    return p / downloadJavaProgress.length;
  }

  bool get finish {
    return finishList.every((b) => b);
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  Widget build(BuildContext context) {
    if (finish) {
      return AlertDialog(
        title: I18nText('launcher.java.install.auto.download.done',
            textAlign: TextAlign.center),
        actions: [
          OkClose(
            onOk: () => widget.onDownloaded?.call(),
          )
        ],
      );
    } else if (isExtractingArchive) {
      return AlertDialog(
        title: I18nText('launcher.java.install.auto.download.extracting',
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [CircularProgressIndicator()],
        ),
      );
    } else {
      return AlertDialog(
        title: I18nText('launcher.java.install.auto.downloading',
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${(downloadProgress * 100).toStringAsFixed(2)}%'),
            LinearProgressIndicator(
              value: downloadProgress,
            ),
          ],
        ),
      );
    }
  }

  Future<void> _start() async {
    downloadJavaProgress =
        List.generate(widget.javaVersions.length, (index) => 0.0);
    finishList = List.generate(widget.javaVersions.length, (index) => false);

    await Future.wait(
        widget.javaVersions.map((version) => _downloadThread(version)));

    isExtractingArchive = true;
    if (mounted) setState(() {});

    await Future.wait(
        widget.javaVersions.map((version) => _extractArchiveThread(version)));
  }

  Future<void> _downloadThread(int version) async {
    final startTime = DateTime.now();
    final port = ReceivePort();

    port.listen((message) {
      if (mounted) {
        setState(() {
          downloadJavaProgress[widget.javaVersions.indexOf(version)] =
              double.parse(message.toString());
        });

        if (kTestMode) {
          finishList[widget.javaVersions.indexOf(version)] = true;
        }
      }
    });

    await compute(
      _downloadJREArchive,
      IsolateOption.create(version, ports: [port]),
    );

    downloadJavaProgress[widget.javaVersions.indexOf(version)] = 1.0;
    if (mounted) setState(() {});
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    logger.info(
        'It took ${duration.inSeconds} Seconds to download Java $version');
  }

  static _downloadJREArchive(IsolateOption<int> option) async {
    option.init();

    // java 16+ files from https://adoptium.net/temurin/archive/
    const Map javaRuntimeUrl = {
      'windows': {
        '8':
            'https://github.com/AdoptOpenJDK/semeru8-binaries/releases/download/jdk8u302-b08_openj9-0.27.0/ibm-semeru-open-jdk_x64_windows_8u302b08_openj9-0.27.0.zip',
        '16':
            'https://github.com/adoptium/temurin16-binaries/releases/download/jdk-16.0.2%2B7/OpenJDK16U-jdk_x64_windows_hotspot_16.0.2_7.zip',
        '17':
            'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.4%2B8/OpenJDK17U-jre_x64_windows_hotspot_17.0.4_8.zip',
      },
      'linux': {
        '8':
            'https://github.com/AdoptOpenJDK/semeru8-binaries/releases/download/jdk8u302-b08_openj9-0.27.0/ibm-semeru-open-jdk_x64_linux_8u302b08_openj9-0.27.0.tar.gz',
        '16':
            'https://github.com/adoptium/temurin16-binaries/releases/download/jdk-16.0.2%2B7/OpenJDK16U-jdk_x64_linux_hotspot_16.0.2_7.tar.gz',
        '17':
            'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.4%2B8/OpenJDK17U-jre_x64_linux_hotspot_17.0.4_8.tar.gz',
      },
      'macos': {
        '8':
            'https://github.com/AdoptOpenJDK/semeru8-binaries/releases/download/jdk8u302-b08_openj9-0.27.0/ibm-semeru-open-jdk_x64_mac_8u302b08_openj9-0.27.0.tar.gz',
        '16':
            'https://github.com/adoptium/temurin16-binaries/releases/download/jdk-16.0.2%2B7/OpenJDK16U-jdk_x64_mac_hotspot_16.0.2_7.tar.gz',
        '17':
            'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.4%2B8/OpenJDK17U-jre_x64_mac_hotspot_17.0.4_8.tar.gz',
      },
      'macos-arm64': {
        '17':
            'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.4%2B8/OpenJDK17U-jre_aarch64_mac_hotspot_17.0.4_8.tar.gz',
      }
    };

    final int javaVersion = option.argument;

    Future<void> download(String url) async {
      await RPMHttpClient().download(
        url,
        join(dataHome.absolute.path, 'jre', javaVersion.toString(),
            'jre.${Platform.isWindows ? 'zip' : 'tar.gz'}'),
        onReceiveProgress: (count, total) => option.sendData(count / total),
      );
    }

    switch (Platform.operatingSystem) {
      case 'windows':
        await download(javaRuntimeUrl['windows'][javaVersion.toString()]);
        break;
      case 'linux':
        await download(javaRuntimeUrl['linux'][javaVersion.toString()]);
        break;
      case 'macos':
        // Apple Silicon is only supported on Java 17 and above
        if (Util.getCPUArchitecture().contains('arm64') && javaVersion >= 17) {
          await download(javaRuntimeUrl['macos-arm64'][javaVersion.toString()]);
        } else {
          await download(javaRuntimeUrl['macos'][javaVersion.toString()]);
        }
        break;
    }

    Isolate.current.kill();
  }

  static Future<void> _extractArchive(IsolateOption<int> option) async {
    option.init();

    final int version = option.argument;

    final Directory root =
        Directory(join(dataHome.absolute.path, 'jre', version.toString()));
    final String inputPath =
        join(root.path, 'jre.${Platform.isWindows ? 'zip' : 'tar.gz'}');

    await extractFileToDisk(inputPath, root.path, asyncWrite: true);
    await File(inputPath).delete();

    final jreRoot = root.listSync().firstWhere((e) => e is Directory);

    late String execPath;

    if (Platform.isWindows) {
      execPath = join(jreRoot.path, 'bin', 'javaw.exe');
    } else if (Platform.isLinux) {
      execPath = join(jreRoot.path, 'bin', 'java');
    } else if (Platform.isMacOS) {
      execPath =
          join(jreRoot.path, 'jre.bundle', 'Contents', 'Home', 'bin', 'java');
    }
    Config.change('java_path_$version', execPath);
    if (!kTestMode) {
      await chmod(execPath);
    }
    Isolate.current.kill();
  }

  Future<void> _extractArchiveThread(int version) async {
    await compute(_extractArchive, IsolateOption.create(version));
    finishList[widget.javaVersions.indexOf(version)] = true;
    if (mounted) setState(() {});
  }
}
