// Web-only implementation: register an HTML iframe with Flutter's platform
// view registry and render it via `HtmlElementView`. Same approach as the
// SportSync v2 website — no API key required because Google permits anyone
// to embed a `maps/embed?pb=...` URL.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:sportsync/core/models/court.dart';

import 'court_map_stub.dart' as stub;

// View factories must be registered exactly once per viewType, otherwise
// Flutter's platform view registry throws on the second registration.
final Set<String> _registered = <String>{};

Widget buildCourtMap(Court court) {
  final mapUrl = court.mapUrl;
  if (mapUrl == null || mapUrl.isEmpty) {
    return stub.buildCourtMap(court);
  }

  final viewType = 'court-map-iframe-${court.id}';
  if (!_registered.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final iframe = html.IFrameElement()
        ..src = mapUrl
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = false
        ..setAttribute('loading', 'lazy')
        ..setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
      return iframe;
    });
    _registered.add(viewType);
  }

  return HtmlElementView(viewType: viewType);
}
