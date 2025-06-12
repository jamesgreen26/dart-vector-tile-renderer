import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:vector_tile_renderer/src/gpu/draw_queue.dart';
import 'package:vector_tile_renderer/src/gpu/line_to_triangles.dart';
import 'package:vector_tile_renderer/src/gpu/math/triangle.dart';
import 'package:vector_tile_renderer/src/themes/theme_layers.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../vector_tile_renderer.dart';
import '../themes/expression/expression.dart';
import '../themes/theme.dart';
import '../tileset.dart';
import 'color_extension.dart';
import 'shaders.dart';

/// Experimental: renders tiles using flutter_gpu
///
/// this class is stateful, designed to be reused for rendering a tile
/// multiple times.
///
class GpuTileRenderer {
  final Theme theme;
  final Logger logger;

  GpuTileRenderer({required this.theme, Logger? logger})
      : logger = logger ?? const Logger.noop();

  void render(
      {required ui.Canvas canvas,
      required ui.Rect clip,
      required double zoomScaleFactor,
      required double zoom,
      required double rotation,
      required Tileset tile}) {
    final effectiveTheme = theme.atZoom(zoom);

    final drawQueue = DrawQueue();

    final evaluationContext = EvaluationContext(
            () => {}, TileFeatureType.none, logger,
        zoom: zoom, zoomScaleFactor: zoomScaleFactor, hasImage: (_) => false);

    for (var layer in effectiveTheme.layers) {
      if (layer is DefaultLayer) {
        for (var tileLayer in layer.selector.select(tile, zoom.truncate())) {
          for (var feature in tileLayer.features) {
            if (feature.modelPolygons != null) {}
            final lines = feature.modelLines;
            if (lines != null) {
              final color = layer.style.linePaint?.evaluate(evaluationContext)?.color.vector4;
              final triangles =
                  lines.map((it) => getTriangles(it, 4096)).flattenedToList;
              drawQueue.addTriangles(triangles, color ?? m.Colors.black.vector4);
            }
            if (feature.modelPoints != null) {}
          }
        }
      }
    }

    final texture = gpu.gpuContext.createTexture(
        gpu.StorageMode.devicePrivate, clip.width.toInt(), clip.height.toInt());
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
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());
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
