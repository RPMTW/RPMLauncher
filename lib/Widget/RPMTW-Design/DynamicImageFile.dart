import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/Utility.dart';

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
  late final Widget defaultImage;

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
  Widget build(BuildContext context) {
    return StreamBuilder<FileSystemEvent>(
      stream: Uttily.fileWatcher(widget.imageFile),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          FileSystemEvent event = snapshot.data!;

          if (event is FileSystemDeleteEvent ||
              !File(event.path).existsSync()) {
            return Icon(
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
