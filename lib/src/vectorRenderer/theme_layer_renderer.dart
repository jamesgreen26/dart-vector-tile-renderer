
import 'dart:ui';

import 'package:vector_tile_renderer/src/features/extensions.dart';
import 'package:vector_tile_renderer/src/themes/theme_layer_raster.dart';
import 'package:vector_tile_renderer/src/tileset.dart';

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../context.dart';
import '../features/tile_space_mapper.dart';
import '../themes/expression/expression.dart';
import '../themes/theme_layers.dart';

class ThemeLayerRenderer {
  void render(Context context, ThemeLayer layer) {
    if (layer is BackgroundLayer) {
      _renderBackground(context, layer);
    } else if (layer is DefaultLayer) {
      _renderDefault(context, layer);
    } else if (layer is ThemeLayerRaster) {
      _renderRaster(context, layer);
    } else {
      throw UnimplementedError("ThemeLayer type not supported for layer: $layer");
    }
  }

  void _renderBackground(Context context, BackgroundLayer backgroundLayer) {
    context.logger.log(() => 'rendering ${backgroundLayer.id}');
    final color = backgroundLayer.fillColor.evaluate(EvaluationContext(
            () => {}, TileFeatureType.background, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false));
    if (color != null) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;
      context.canvas.drawRect(context.tileClip, paint);
    }
  }

  void _renderDefault(Context context, DefaultLayer defaultLayer) {
    final layers =
    defaultLayer.selector.select(context.tileSource.tileset, context.zoom.truncate());
    if (layers.isEmpty) {
      return;
    }

    final features = context.tileSource.tileset.resolver
        .resolveFeatures(defaultLayer.selector, context.zoom.truncate());

    if (features.isEmpty) {
      return;
    }

    for (final layer in layers) {
      context.tileSpaceMapper = TileSpaceMapper(
        context.canvas,
        context.tileClip,
        tileSize,
        layer.extent,
      );

      context.tileSpaceMapper.drawInTileSpace(() {
        for (final feature in features) {
          context.featureRenderer.render(
            context,
            defaultLayer.type,
            defaultLayer.style,
            feature.layer,
            feature.feature,
          );
        }
      });
    }
  }

  void _renderRaster(Context context, ThemeLayerRaster rasterLayer) {
    final image = context.tileSource.rasterTileset.tiles[rasterLayer.tileSource];
    if (image != null) {
      _renderImage(context, rasterLayer, image);
    }
  }

  void _renderImage(Context context, ThemeLayerRaster rasterLayer, RasterTile image) {
    final evaluationContext = EvaluationContext(
            () => {}, TileFeatureType.none, context.logger,
        zoom: context.zoom,
        zoomScaleFactor: context.zoomScaleFactor,
        hasImage: context.hasImage);
    final opacity = rasterLayer.paintModel.opacity.evaluate(evaluationContext) ?? 1.0;
    if (opacity > 0.0) {
      final paint = Paint()
        ..color = Color.fromARGB((opacity * 255).round().clamp(0, 255), 0, 0, 0)
        ..isAntiAlias = true
        ..filterQuality = _filterQuality(evaluationContext, rasterLayer);
      if (image.scope == context.tileSpace) {
        context.canvas
            .drawImageRect(image.image, image.scope, context.tileSpace, paint);
      } else {
        final scale = context.tileClip.width / image.scope.width;
        context.canvas.drawAtlas(
            image.image,
            [
              RSTransform.fromComponents(
                  rotation: 0.0,
                  scale: scale,
                  anchorX: 0.0,
                  anchorY: 0.0,
                  translateX: context.tileClip.left,
                  translateY: context.tileClip.top),
            ],
            [image.scope],
            null,
            null,
            null,
            paint);
      }
    }
  }

  FilterQuality _filterQuality(EvaluationContext context, ThemeLayerRaster rasterLayer) {
    final resampling = rasterLayer.paintModel.rasterResampling.evaluate(context);
    if (resampling == 'nearest') {
      return FilterQuality.none;
    }
    return FilterQuality.medium;
  }
}