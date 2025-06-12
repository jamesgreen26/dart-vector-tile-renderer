import 'dart:ui';

import '../constants.dart';
import '../context.dart';
import '../features/tile_space_mapper.dart';
import '../model/tile_model.dart';
import '../tileset.dart';
import 'expression/expression.dart';
import 'selector.dart';
import 'style.dart';
import 'theme.dart';

class DefaultLayer extends ThemeLayer {
  final TileLayerSelector selector;
  final Style style;

  DefaultLayer(super.id, super.type,
      {required this.selector,
      required this.style,
      required super.minzoom,
      required super.maxzoom,
      required super.metadata});

  @override
  String? get tileSource => selector.tileSelector.source;
}

class BackgroundLayer extends ThemeLayer {
  final Expression<Color> fillColor;

  BackgroundLayer(String id, this.fillColor, Map<String, dynamic> metadata)
      : super(id, ThemeLayerType.background,
            minzoom: 0, maxzoom: 24, metadata: metadata);

  @override
  String? get tileSource => null;
}
