import 'package:flutter/material.dart';

class RPMNetworkImage extends StatelessWidget {
  final String src;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const RPMNetworkImage(
      {Key? key, required this.src, this.fit, this.width, this.height})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Image.network(
      src,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded.toInt() /
                    loadingProgress.expectedTotalBytes!.toInt()
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
