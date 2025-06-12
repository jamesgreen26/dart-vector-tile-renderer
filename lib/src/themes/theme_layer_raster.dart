import 'package:flutter/painting.dart';

import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../features/extensions.dart';
import 'expression/expression.dart';
import 'selector.dart';

class RasterPaintModel {
  final Expression<double> opacity;
  final Expression<String?> rasterResampling;

  RasterPaintModel({required this.opacity, required this.rasterResampling});
}

class ThemeLayerRaster extends ThemeLayer {
  final TileLayerSelector selector;
  final RasterPaintModel paintModel;
  ThemeLayerRaster(super.id, super.type,
      {required this.selector,
      required this.paintModel,
      required super.minzoom,
      required super.maxzoom,
      required super.metadata});

  @override
  String? get tileSource => selector.tileSelector.source;
}
