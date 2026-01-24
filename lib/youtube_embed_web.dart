// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: deprecated_member_use
import 'dart:ui_web' as ui;
import 'package:flutter/widgets.dart';

final _registeredYouTubeViews = <String>{};

Widget buildYouTubeEmbed(String videoId) {
  final viewType = 'youtube-embed-$videoId';
  if (!_registeredYouTubeViews.contains(viewType)) {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final origin = html.window.location.origin;
      final iframe = html.IFrameElement()
        ..style.border = '0'
        ..allowFullscreen = true
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen'
        ..src =
            'https://www.youtube-nocookie.com/embed/$videoId'
            '?rel=0'
            '&playsinline=1'
            '&modestbranding=1'
            '&controls=1'
            '&iv_load_policy=3'
            '&showinfo=0'
            '&fs=1'
            '&loop=1'
            '&playlist=$videoId'
            '&origin=$origin'
            '&widget_referrer=$origin';
      return iframe;
    });
    _registeredYouTubeViews.add(viewType);
  }
  return HtmlElementView(viewType: viewType);
}
