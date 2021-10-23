import 'package:flutter/material.dart';

class RPMNetworkImage extends StatelessWidget {
  final String src;

  const RPMNetworkImage({Key? key, required this.src}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Image.network(
      src,
      fit: BoxFit.contain,
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
    );
  }
}
