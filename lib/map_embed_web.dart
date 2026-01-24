// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/widgets.dart';

final _registeredMapEmbeds = <String>{};

Widget buildMapEmbed(String mapUrl, {bool forceUnique = false}) {
  final viewType = forceUnique ? 'map-embed-${DateTime.now().microsecondsSinceEpoch}' : 'map-embed-${mapUrl.hashCode}';
  if (!_registeredMapEmbeds.contains(viewType)) {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final iframe = html.IFrameElement()
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..setAttribute('allowfullscreen', '')
        ..allow = 'accelerometer; autoplay; encrypted-media; fullscreen; geolocation; picture-in-picture'
        ..src = mapUrl;
      iframe.sandbox!
        ..add('allow-same-origin')
        ..add('allow-scripts')
        ..add('allow-forms')
        ..add('allow-pointer-lock');
      return iframe;
    });
    _registeredMapEmbeds.add(viewType);
  }
  return HtmlElementView(viewType: viewType);
}
