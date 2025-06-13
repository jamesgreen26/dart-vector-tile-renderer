import 'package:vector_math/vector_math.dart' hide Triangle;

import 'math/triangle.dart';

import 'dart:typed_data';

class DrawQueue {
  Float32List coloredVertices = Float32List(0); //must be initialized
  int vertexCount = 0;
  int _capacity = 0;
  bool _hasData = false;

  DrawQueue({int initialCapacity = 1024}) {
    _capacity = initialCapacity;
    coloredVertices = Float32List(_capacity * 6);
  }

  bool get hasData => _hasData;

  void addTriangles(List<Triangle> triangles, Vector4 color) {
    _hasData = true;
    int required = triangles.length * 3 * 6;

    if (vertexCount * 6 + required > coloredVertices.length) {
      _growBuffer((vertexCount * 6 + required) * 2);
    }

    int i = vertexCount * 6;

    for (var triangle in triangles) {
      i = _writeVertex(coloredVertices, i, triangle.a, color);
      i = _writeVertex(coloredVertices, i, triangle.b, color);
      i = _writeVertex(coloredVertices, i, triangle.c, color);
      vertexCount += 3;
    }
  }

  int _writeVertex(Float32List buffer, int index, Vector2 pos, Vector4 color) {
    buffer[index++] = pos.x;
    buffer[index++] = pos.y;
    buffer[index++] = color.r;
    buffer[index++] = color.g;
    buffer[index++] = color.b;
    buffer[index++] = color.a;
    return index;
  }

  void _growBuffer(int newLength) {
    final newBuffer = Float32List(newLength);
    newBuffer.setRange(0, coloredVertices.length, coloredVertices);
    coloredVertices = newBuffer;
    _capacity = newLength ~/ 6;
  }
}
