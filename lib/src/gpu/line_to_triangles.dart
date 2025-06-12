import 'package:vector_math/vector_math.dart' as vm;

import '../model/geometry_model.dart';
import 'math/triangle.dart';

List<Triangle> getTriangles(TileLine line, int extent) {
  List<vm.Vector2> points = line.points.map((p) =>  vm.Vector2((-1 + 2 * p.x / extent), (1 - 2 * p.y / extent))).toList();
  if (points.isEmpty) return List.empty();
  var width = 0.002;

  var deltas = getDeltas(points);
  var turnAmounts = getTurnAmounts(deltas);

  List<Triangle> triangles = [];

  for (int i = 0; i < points.length - 1; i++) {
    var delta = deltas[i].normalized();
    var normalMatrix = vm.Matrix2(0, -1, 1, 0);
    var normal = normalMatrix.transformed(delta, vm.Vector2(0.0, 0.0));

    triangles.add(Triangle(
        points[i] + (normal * width) + (delta * turnAmounts[i] * width / 2),
        points[i] - (normal * width) + (delta * turnAmounts[i] * width / 2),
        points[i + 1] + (normal * width) - (delta * turnAmounts[i + 1] * width / 2)
    ));

    triangles.add(Triangle(
        points[i + 1] + (normal * width) - (delta * turnAmounts[i + 1] * width / 2),
        points[i + 1] - (normal * width) - (delta * turnAmounts[i + 1] * width / 2),
        points[i] - (normal * width) + (delta * turnAmounts[i] * width / 2)
    ));

    if (turnAmounts[i + 1] > 0) {
      var delta2 = deltas[i + 1].normalized();
      var normal2 = normalMatrix.transformed(delta2, vm.Vector2(0.0, 0.0));


      triangles.add(Triangle(
          points[i + 1] + (normal * width) - (delta * turnAmounts[i + 1] * width / 2),
          points[i + 1] - (normal * width) - (delta * turnAmounts[i + 1] * width / 2),
          points[i + 1] + (normal2 * width) + (delta2 * turnAmounts[i + 1] * width / 2)
      ));

      triangles.add(Triangle(
          points[i + 1] + (normal2 * width) + (delta2 * turnAmounts[i + 1] * width / 2),
          points[i + 1] - (normal2 * width) + (delta2 * turnAmounts[i + 1] * width / 2),
          points[i + 1] - (normal * width) - (delta * turnAmounts[i + 1] * width / 2)
      ));
    }
  }
  return triangles;
}

List<vm.Vector2> getDeltas(List<vm.Vector2> points) {
  List<vm.Vector2> output = [];
  for (int i = 0; i < points.length - 1; i++) {
    output.add((points[i + 1] - points[i]));
  }
  return output;
}

List<double> getTurnAmounts(List<vm.Vector2> deltas) {
  List<double> output = [];
  output.add(0.0);
  for (int i = 0; i < deltas.length - 1; i++) {
    var dp = deltas[i].dot(deltas[i + 1]);
    output.add((1 - dp));
  }
  output.add(0.0);
  return output;
}