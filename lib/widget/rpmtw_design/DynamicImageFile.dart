import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/util.dart';

class DynamicImageFile extends StatefulWidget {
  const DynamicImageFile({
    Key? key,
    required this.imageFile,
    this.width,
    this.height,
  }) : super(key: key);

  final File imageFile;
  final double? width;
  final double? height;

  @override
  State<DynamicImageFile> createState() => _DynamicImageFileState();
}

class _DynamicImageFileState extends State<DynamicImageFile> {
  late Widget defaultImage;

  @override
  void initState() {
    defaultImage = Image.file(
      widget.imageFile,
      width: widget.width,
      height: widget.height,
    );

    super.initState();
  }

  @override
  void didUpdateWidget(covariant DynamicImageFile oldWidget) {
    if (oldWidget.imageFile.path != widget.imageFile.path) {
      defaultImage = Image.file(
        widget.imageFile,
        width: widget.width,
        height: widget.height,
      );
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FileSystemEvent>(
      stream: Util.fileWatcher(widget.imageFile),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          FileSystemEvent event = snapshot.data!;

          if (event is FileSystemDeleteEvent ||
              !File(event.path).existsSync()) {
            return const Icon(
              Icons.image,
              size: 75,
            );
          } else {
            return Image.memory(
              widget.imageFile.readAsBytesSync(),
              width: widget.width,
              height: widget.height,
            );
          }
        } else {
          return defaultImage;
        }
      },
    );
  }
}
