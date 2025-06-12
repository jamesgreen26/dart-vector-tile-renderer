import 'dart:math';

import 'package:vector_tile_renderer/src/gpu/math/triangle.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:dart_earcut/dart_earcut.dart';


List<Triangle> earcutPolygons(List<Point> points) {

  final flatList = <double>[];
  for (final p in points) {
    flatList.addAll([p.x.toDouble(), p.y.toDouble()]);
  }

  final indices = Earcut.triangulateRaw(flatList);

  final triangles = <Triangle>[];
  for (int i = 0; i < indices.length; i += 3) {
    final a = points[indices[i]];
    final b = points[indices[i + 1]];
    final c = points[indices[i + 2]];

    triangles.add(
      Triangle(
        vm.Vector2(a.x / 2048 - 1, 1 - a.y / 2048),
        vm.Vector2(b.x / 2048 - 1, 1 - b.y / 2048),
        vm.Vector2(c.x / 2048 - 1, 1 - c.y / 2048),
      ),
    );

  }

  return triangles;
}