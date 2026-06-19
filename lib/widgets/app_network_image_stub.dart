import 'package:flutter/material.dart';

class AppNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.imageUrl,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        );
      },
    );
  }
}
