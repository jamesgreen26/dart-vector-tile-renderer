import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:vector_tile_renderer/src/gpu/draw_queue.dart';
import 'package:vector_tile_renderer/src/gpu/line_to_triangles.dart';
import 'package:vector_tile_renderer/src/themes/theme_layers.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../themes/expression/expression.dart';
import '../themes/theme.dart';
import '../tileset.dart';
import 'color_extension.dart';
import 'earcut_polygons.dart';
import 'shaders.dart';

/// Experimental: renders tiles using flutter_gpu
///
/// this class is stateful, designed to be reused for rendering a tile
/// multiple times.
///
class GpuTileRenderer {
  late final Theme theme;
  final Logger logger;
  DrawQueue drawQueue = DrawQueue();
  double previousZoom = double.nan;

  GpuTileRenderer({Logger? logger})
      : logger = logger ?? const Logger.noop();

  void render(
      {required ui.Canvas canvas,
        required ui.Rect clip,
        required double zoomScaleFactor,
        required double zoom,
        required double rotation,
        required Tileset tile}) {
    final effectiveTheme = theme.atZoom(zoom);

    final tileSpace = ui.Rect.fromLTWH(0, 0, tileSize.toDouble(), tileSize.toDouble());
    final drawSpace = ui.Rect.fromLTWH(0, 0, min(tileSpace.width * zoomScaleFactor, 16384), min(tileSpace.height * zoomScaleFactor, 16384));

    if (!drawQueue.hasData || zoom != previousZoom) {
      drawQueue = DrawQueue();
      previousZoom = zoom;
      computeDrawQueue(zoom, zoomScaleFactor, effectiveTheme, tile);
    }

    final texture = gpu.gpuContext.createTexture(
        gpu.StorageMode.devicePrivate, drawSpace.width.toInt(), drawSpace.height.toInt());
    final renderTarget = gpu.RenderTarget.singleColor(gpu.ColorAttachment(
        texture: texture,
        clearValue: _getBackgroundColor(effectiveTheme.layers.first, zoom)));

    final commandBuffer = gpu.gpuContext.createCommandBuffer();
    final renderPass = commandBuffer.createRenderPass(renderTarget);

    final vert = shaderLibrary['SimpleVertex']!;
    final frag = shaderLibrary['SimpleFragment']!;
    final pipeline = gpu.gpuContext.createRenderPipeline(vert, frag);

    final verticesDeviceBuffer = gpu.gpuContext.createDeviceBufferWithCopy(
        ByteData.sublistView(
            Float32List.fromList(drawQueue.coloredVertices)));

    renderPass.bindPipeline(pipeline);
    renderPass.setPrimitiveType(gpu.PrimitiveType.triangle);

    final verticesView = gpu.BufferView(
      verticesDeviceBuffer,
      offsetInBytes: 0,
      lengthInBytes: verticesDeviceBuffer.sizeInBytes,
    );
    renderPass.bindVertexBuffer(
        verticesView, drawQueue.vertexCount);
    renderPass.draw();

    commandBuffer.submit();
    final image = texture.asImage();
    canvas.drawImageRect(image, drawSpace, tileSpace, ui.Paint());
  }

  void computeDrawQueue(double zoom, double zoomScaleFactor, Theme effectiveTheme, Tileset tile) {
    final evaluationContext = EvaluationContext(
            () => {}, TileFeatureType.none, logger,
        zoom: zoom, zoomScaleFactor: zoomScaleFactor, hasImage: (_) => false);

    for (var layer in effectiveTheme.layers) {
      if (layer is DefaultLayer) {
        for (var tileLayer in layer.selector.select(tile, zoom.truncate())) {
          for (var feature in tileLayer.features) {

            final polygons = feature.modelPolygons;
            final lines = feature.modelLines;
            final points = feature.modelPoints;

            final linePaint = layer.style.linePaint?.evaluate(evaluationContext);
            final fillPaint = layer.style.fillPaint?.evaluate(evaluationContext);

            if (polygons != null && fillPaint != null) {
              final triangles = polygons.map((it) =>
                  earcutPolygons(it.rings
                      .map((it2) => it2.points)
                      .flattenedToList));
              final color = fillPaint.color.vector4;
              drawQueue.addTriangles(triangles.flattenedToList, color);
            }
            if (lines != null && linePaint != null) {
              final color = linePaint.color.vector4;
              final strokeWidth = linePaint.strokeWidth;
              final triangles = lines
                      .map((it) => getTriangles(it, 4096, strokeWidth ?? 8))
                      .flattenedToList;
              drawQueue.addTriangles(
                  triangles, color);
            }
            if (points != null) {}
          }
        }
      }
    }
  }

  vm.Vector4 _getBackgroundColor(ThemeLayer baseLayer, double zoom) {
    if (baseLayer is BackgroundLayer) {
      final color = baseLayer.fillColor.evaluate(EvaluationContext(
          () => {}, TileFeatureType.background, logger,
          zoom: zoom, zoomScaleFactor: 1.0, hasImage: (_) => false));
      if (color != null) {
        return color.vector4;
      }
    }
    return m.Colors.orange.vector4;
  }

  /// Must call to release resources when done.
  void dispose() {}
}
