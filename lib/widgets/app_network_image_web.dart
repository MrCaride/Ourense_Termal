import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

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
  static final Map<String, String> _viewTypesByUrl = {};

  late String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = _ensureViewType(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _viewType = _ensureViewType(widget.imageUrl);
    }
  }

  String _ensureViewType(String imageUrl) {
    return _viewTypesByUrl.putIfAbsent(imageUrl, () {
      final viewType = 'app-network-image-${_viewTypesByUrl.length}';
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final image = html.ImageElement()
          ..src = imageUrl
          ..alt = ''
          ..draggable = false
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = _cssObjectFit(widget.fit)
          ..style.objectPosition = 'center center';

        image.onContextMenu.listen((event) => event.preventDefault());
        return image;
      });
      return viewType;
    });
  }

  String _cssObjectFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.fill:
        return 'fill';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fitWidth:
        return 'cover';
      case BoxFit.fitHeight:
        return 'cover';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
