import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/sdf_atlas_manager.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_material.dart';
import 'package:vector_tile_renderer/src/features/label_space.dart';

class BoundingBox {
  double minX = double.infinity;
  double maxX = double.negativeInfinity;
  double minY = double.infinity;
  double maxY = double.negativeInfinity;

  void updateBounds(
      double charMinX, double charMaxX, double charMinY, double charMaxY) {
    minX = minX < charMinX ? minX : charMinX;
    maxX = maxX > charMaxX ? maxX : charMaxX;
    minY = minY < charMinY ? minY : charMinY;
    maxY = maxY > charMaxY ? maxY : charMaxY;
  }

  double get centerOffsetX => -(minX + maxX) / 2;

  double get centerOffsetY => -(minY + maxY) / 2;

  double get sizeX => maxX - minX;
  double get sizeY => maxY - minY;
}

class TextBuilder {
  final SdfAtlasManager atlasManager;

  TextBuilder(this.atlasManager);

  Future<bool> addTextWithCollisionDetection(
    String text,
    int fontSize,
    double x,
    double y,
    int canvasSize,
    SceneGraph scene,
    LabelSpace labelSpace,
    double zoom,
  ) async {
    if (!labelSpace.canAccept(text)) {
      return false;
    }

    final boundingBox =
        await _calculateBoundingBox(text, fontSize, x, y, canvasSize, zoom);
    if (boundingBox == null) {
      return false;
    }

    final screenRect = _boundingBoxToRect(boundingBox, x, y, canvasSize);

    if (!labelSpace.canOccupy(text, screenRect)) {
      return false;
    }

    labelSpace.occupy(text, screenRect);

    await _addTextToScene(text, fontSize, x, y, canvasSize, scene, zoom);
    return true;
  }

  Future<void> addText(String text, int fontSize, double x, double y,
      int canvasSize, SceneGraph scene) async {
    await _addTextToScene(text, fontSize, x, y, canvasSize, scene, 1.0);
  }

  Future<BoundingBox?> _calculateBoundingBox(
    String text,
    int fontSize,
    double x,
    double y,
    int canvasSize,
    double zoom,
  ) async {
    final atlas = await atlasManager.getAtlasForString(text, "Roboto Regular");
    final boundingBox = BoundingBox();

    final zoomAdjustedFontSize = fontSize * _getZoomScale(zoom);
    final fontScale = zoomAdjustedFontSize / atlas.fontSize;
    final canvasScale = 2 / canvasSize;
    final scaling = fontScale * canvasScale;

    double offsetX = 0.0;

    for (final charCode in text.codeUnits) {
      if (charCode > 255) {
        continue;
      }

      final glyphMetrics = atlas.getGlyphMetrics(charCode);
      if (glyphMetrics == null) {
        continue;
      }

      offsetX -= glyphMetrics.glyphLeft * scaling;

      final halfHeight = scaling * atlas.cellHeight / 2;
      final halfWidth = scaling * atlas.cellWidth / 2;

      final charMinX = offsetX - halfWidth;
      final charMaxX = offsetX + halfWidth;
      final charMinY = -halfHeight;
      final charMaxY = halfHeight;

      boundingBox.updateBounds(charMinX, charMaxX, charMinY, charMaxY);

      final advance = scaling * glyphMetrics.glyphAdvance;
      offsetX += advance;
      offsetX += glyphMetrics.glyphLeft * scaling;
    }

    return boundingBox;
  }

  Rect _boundingBoxToRect(
      BoundingBox boundingBox, double x, double y, int canvasSize) {
    final screenX = x;
    final screenY = y;

    final left = screenX + boundingBox.minX * canvasSize / 2;
    final right = screenX + boundingBox.maxX * canvasSize / 2;
    final top = screenY + boundingBox.minY * canvasSize / 2;
    final bottom = screenY + boundingBox.maxY * canvasSize / 2;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  double _getZoomScale(double zoom) {
    // Scale text size based on zoom level
    // At zoom 1.0, use normal size
    // At higher zooms, increase text size
    // At lower zooms, decrease text size
    return (0.5 + (zoom * 0.5)).clamp(0.3, 2.0);
  }

  Future<void> _addTextToScene(
    String text,
    int fontSize,
    double x,
    double y,
    int canvasSize,
    SceneGraph scene,
    double zoom,
  ) async {
    final atlas = await atlasManager.getAtlasForString(text, "Roboto Regular");

    final tempVertices = <double>[];
    final indices = <int>[];
    final boundingBox = BoundingBox();

    final zoomAdjustedFontSize = fontSize * _getZoomScale(zoom);
    final fontScale = zoomAdjustedFontSize / atlas.fontSize;
    final canvasScale = 2 / canvasSize;
    final scaling = fontScale * canvasScale;

    double offsetX = 0.0;
    int vertexIndex = 0;

    final anchorX = (x - canvasSize / 2) * canvasScale;
    final anchorY = (y - canvasSize / 2) * canvasScale;

    for (final charCode in text.codeUnits) {
      if (charCode > 255) {
        continue;
      }

      final glyphMetrics = atlas.getGlyphMetrics(charCode)!;

      offsetX -= glyphMetrics.glyphLeft * scaling;

      final uv = atlas.getCharacterUV(charCode);

      final double top = uv.v1;
      final double bottom = uv.v2;
      final double left = uv.u1;
      final double right = uv.u2;

      final halfHeight = scaling * atlas.cellHeight / 2;
      final halfWidth = scaling * atlas.cellWidth / 2;

      final charMinX = offsetX - halfWidth;
      final charMaxX = offsetX + halfWidth;
      final charMinY = -halfHeight;
      final charMaxY = halfHeight;

      boundingBox.updateBounds(charMinX, charMaxX, charMinY, charMaxY);

      tempVertices.addAll([
        charMinX,
        charMinY,
        0,
        left,
        bottom,
        charMaxX,
        charMinY,
        0,
        right,
        bottom,
        charMaxX,
        charMaxY,
        0,
        right,
        top,
        charMinX,
        charMaxY,
        0,
        left,
        top,
      ]);

      indices.addAll([
        vertexIndex + 0,
        vertexIndex + 2,
        vertexIndex + 1,
        vertexIndex + 2,
        vertexIndex + 0,
        vertexIndex + 3,
      ]);
      final advance = scaling * glyphMetrics.glyphAdvance;

      offsetX += advance;
      offsetX += glyphMetrics.glyphLeft * scaling;

      vertexIndex += 4;
    }

    final centerOffsetX = boundingBox.centerOffsetX;
    final centerOffsetY = boundingBox.centerOffsetY;

    final vertices = <double>[];
    for (int i = 0; i < tempVertices.length; i += 5) {
      vertices.addAll([
        tempVertices[i] + centerOffsetX,
        tempVertices[i + 1] + centerOffsetY,
        tempVertices[i + 3],
        tempVertices[i + 4],
        anchorX - (boundingBox.sizeX / 2),
        -anchorY - (boundingBox.sizeY / 2),
        anchorX + (boundingBox.sizeX / 2),
        -anchorY + (boundingBox.sizeY / 2),
      ]);
    }

    final geom = TextGeometry(
        ByteData.sublistView(Float32List.fromList(vertices)),
        ByteData.sublistView(Uint16List.fromList(indices)),
        8);

    final mat = TextMaterial(atlas.texture, 0.08, 0.75 / expand, color);

    final node = Node();

    node.addMesh(Mesh(geom, mat));

    /// force symbols in front of other layers. We do it this way to ensure that text does not get drawn underneath
    /// layers from a neighboring tile. TODO: instead, group layers from all tiles together and draw the groups in order
    node.localTransform = node.localTransform
      ..translate(0.0, 0.0, 0.00001 * expand);

    scene.add(node);
  }
}
