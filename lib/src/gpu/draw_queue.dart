import 'package:vector_math/vector_math.dart' hide Triangle;

import 'math/triangle.dart';

class DrawQueue {
  final coloredVertices = <double>[];
  int vertexCount = 0;

  void addTriangles(List<Triangle> triangles, Vector4 color) {
    for (var triangle in triangles) {
      coloredVertices.addAll([
        triangle.a.x,
        triangle.a.y,
        color.r,
        color.g,
        color.b,
        color.a,
        triangle.b.x,
        triangle.b.y,
        color.r,
        color.g,
        color.b,
        color.a,
        triangle.c.x,
        triangle.c.y,
        color.r,
        color.g,
        color.b,
        color.a
      ]);
      vertexCount += 3;
    }
  }
}
